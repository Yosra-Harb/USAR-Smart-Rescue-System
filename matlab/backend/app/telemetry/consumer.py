from __future__ import annotations

import copy
import json
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any

from app.core.errors import TelemetryIntegrityError


_ALLOWED_EVENTS = {
    "MISSION_STARTED",
    "STEP",
    "VICTIM_TRACK_CREATED",
    "MISSION_COMPLETED",
}

_FORBIDDEN_KEY_FRAGMENTS = (
    "groundtruth",
    "oracle",
)


@dataclass
class MissionStreamState:
    mission_id: str
    committed_offset: int = 0
    last_sequence: int = -1
    records: list[dict[str, Any]] = field(default_factory=list)

    status: str = "UNKNOWN"
    started_at_utc: str | None = None
    latest_timestamp_utc: str | None = None

    scenario: dict[str, Any] | None = None
    probe: dict[str, Any] | None = None
    sensors: dict[str, Any] | None = None
    fusion: dict[str, Any] | None = None
    localization: dict[str, Any] | None = None
    vitality: dict[str, Any] | None = None
    priority: dict[str, Any] | None = None
    decision: str | None = None

    active_track_count: int = 0
    tracks: dict[int, dict[str, Any]] = field(default_factory=dict)
    completed_summary: dict[str, Any] | None = None

    def snapshot(self) -> dict[str, Any]:
        return {
            "schemaVersion": "1.0",
            "contractType": "mission-operational-state",
            "missionId": self.mission_id,
            "status": self.status,
            "lastSequence": self.last_sequence,
            "startedAtUtc": self.started_at_utc,
            "latestTimestampUtc": self.latest_timestamp_utc,
            "elapsedSeconds": self._elapsed_seconds(),
            "scenario": copy.deepcopy(self.scenario),
            "probe": copy.deepcopy(self.probe),
            "sensors": copy.deepcopy(self.sensors),
            "fusion": copy.deepcopy(self.fusion),
            "localization": copy.deepcopy(self.localization),
            "vitality": copy.deepcopy(self.vitality),
            "priority": copy.deepcopy(self.priority),
            "decision": self.decision,
            "activeTrackCount": self.active_track_count,
            "tracks": [
                copy.deepcopy(self.tracks[key])
                for key in sorted(self.tracks)
            ],
            "completedSummary": copy.deepcopy(
                self.completed_summary
            ),
            "containsGroundTruth": False,
        }

    def _elapsed_seconds(self) -> float:
        if (
            self.started_at_utc is None
            or self.latest_timestamp_utc is None
        ):
            return 0.0

        try:
            start = _parse_utc(self.started_at_utc)
            latest = _parse_utc(self.latest_timestamp_utc)
        except ValueError:
            return 0.0

        return max(
            0.0,
            (latest - start).total_seconds(),
        )


class MissionTelemetryConsumer:
    """Incrementally tails append-only telemetry.jsonl files.

    It remembers the byte offset already committed, so repeated API calls
    read only new complete lines. A partially-written final line is never
    committed until MATLAB finishes writing its newline.
    """

    def __init__(self) -> None:
        self._states: dict[str, MissionStreamState] = {}

    def refresh(
        self,
        mission_id: str,
        telemetry_path: Path,
    ) -> MissionStreamState:
        state = self._states.get(mission_id)

        if state is None:
            state = MissionStreamState(mission_id=mission_id)
            self._states[mission_id] = state

        file_size = telemetry_path.stat().st_size

        # If the mission file was replaced/truncated, rebuild from zero.
        if file_size < state.committed_offset:
            state = MissionStreamState(mission_id=mission_id)
            self._states[mission_id] = state

        with telemetry_path.open("rb") as stream:
            stream.seek(state.committed_offset)
            chunk = stream.read()

        if not chunk:
            return state

        cursor = 0

        while cursor < len(chunk):
            newline_index = chunk.find(b"\n", cursor)

            # MATLAB writes one JSON object + newline atomically enough for our
            # file contract. If the last line is incomplete, leave it unread.
            if newline_index < 0:
                break

            line_end = newline_index + 1
            raw_line = chunk[cursor:newline_index].strip()

            if raw_line:
                self._consume_line(state, raw_line)

            cursor = line_end

        state.committed_offset += cursor
        return state

    def get_events(
        self,
        state: MissionStreamState,
        *,
        after_sequence: int,
        limit: int,
    ) -> list[dict[str, Any]]:
        return [
            copy.deepcopy(record)
            for record in state.records
            if int(record["sequence"]) > after_sequence
        ][:limit]

    def _consume_line(
        self,
        state: MissionStreamState,
        raw_line: bytes,
    ) -> None:
        try:
            record = json.loads(raw_line.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise TelemetryIntegrityError(
                "A complete telemetry line is not valid UTF-8 JSON."
            ) from exc

        if not isinstance(record, dict):
            raise TelemetryIntegrityError(
                "Each telemetry line must be one JSON object."
            )

        self._validate_record(state, record)
        self._apply_record(state, record)

        state.records.append(record)
        state.last_sequence = int(record["sequence"])
        state.latest_timestamp_utc = str(record["timestampUtc"])

    @staticmethod
    def _validate_record(
        state: MissionStreamState,
        record: dict[str, Any],
    ) -> None:
        if record.get("schemaVersion") != "1.1":
            raise TelemetryIntegrityError(
                "Only telemetry schemaVersion 1.1 is accepted."
            )

        if record.get("contractType") != "mission-telemetry":
            raise TelemetryIntegrityError(
                "Unexpected telemetry contractType."
            )

        if record.get("missionId") != state.mission_id:
            raise TelemetryIntegrityError(
                "Telemetry missionId does not match mission folder."
            )

        expected_sequence = state.last_sequence + 1

        if record.get("sequence") != expected_sequence:
            raise TelemetryIntegrityError(
                "Telemetry sequence discontinuity: "
                f"expected {expected_sequence}, "
                f"received {record.get('sequence')}."
            )

        if record.get("eventType") not in _ALLOWED_EVENTS:
            raise TelemetryIntegrityError(
                f"Unsupported telemetry eventType: "
                f"{record.get('eventType')!r}."
            )

        if record.get("containsGroundTruth") is not False:
            raise TelemetryIntegrityError(
                "Operational telemetry must explicitly declare "
                "containsGroundTruth=false."
            )

        _assert_no_forbidden_keys(record)

        try:
            _parse_utc(str(record["timestampUtc"]))
        except (KeyError, ValueError) as exc:
            raise TelemetryIntegrityError(
                "timestampUtc is missing or invalid."
            ) from exc

        if state.latest_timestamp_utc is not None:
            previous = _parse_utc(state.latest_timestamp_utc)
            current = _parse_utc(str(record["timestampUtc"]))

            if current < previous:
                raise TelemetryIntegrityError(
                    "Telemetry timestamps moved backwards."
                )

    @staticmethod
    def _apply_record(
        state: MissionStreamState,
        record: dict[str, Any],
    ) -> None:
        event_type = str(record["eventType"])

        if event_type == "MISSION_STARTED":
            if state.last_sequence != -1:
                raise TelemetryIntegrityError(
                    "MISSION_STARTED must be the first record."
                )

            state.status = "RUNNING"
            state.started_at_utc = str(record["timestampUtc"])
            state.scenario = copy.deepcopy(record.get("scenario"))
            return

        if state.started_at_utc is None:
            raise TelemetryIntegrityError(
                "Operational telemetry arrived before MISSION_STARTED."
            )

        if event_type in {"STEP", "VICTIM_TRACK_CREATED"}:
            if state.status == "COMPLETED":
                raise TelemetryIntegrityError(
                    "Runtime telemetry arrived after mission completion."
                )

            state.status = "RUNNING"

            for field_name in (
                "probe",
                "sensors",
                "fusion",
                "localization",
                "vitality",
                "priority",
            ):
                value = record.get(field_name)
                if isinstance(value, dict):
                    setattr(
                        state,
                        field_name,
                        copy.deepcopy(value),
                    )

            decision = record.get("decision")
            if decision is not None:
                state.decision = str(decision)

            active_track_count = record.get("activeTrackCount")
            if isinstance(active_track_count, int):
                state.active_track_count = active_track_count
            elif isinstance(active_track_count, float):
                state.active_track_count = int(active_track_count)

            if event_type == "VICTIM_TRACK_CREATED":
                new_tracks = record.get("newTracks", [])

                if isinstance(new_tracks, dict):
                    new_tracks = [new_tracks]

                if not isinstance(new_tracks, list):
                    raise TelemetryIntegrityError(
                        "newTracks must be an array or object."
                    )

                for track in new_tracks:
                    if not isinstance(track, dict):
                        raise TelemetryIntegrityError(
                            "Each new track must be an object."
                        )

                    track_id = track.get("id")

                    if (
                        not isinstance(track_id, int)
                        or isinstance(track_id, bool)
                        or track_id <= 0
                    ):
                        raise TelemetryIntegrityError(
                            "Track IDs must be positive integers."
                        )

                    state.tracks[track_id] = copy.deepcopy(track)

            return

        if event_type == "MISSION_COMPLETED":
            state.status = "COMPLETED"
            summary = record.get("summary")
            state.completed_summary = (
                copy.deepcopy(summary)
                if isinstance(summary, dict)
                else None
            )
            return

        raise TelemetryIntegrityError(
            f"Unsupported event type: {event_type}"
        )


def _assert_no_forbidden_keys(value: Any) -> None:
    if isinstance(value, dict):
        for key, nested_value in value.items():
            normalized = str(key).replace("_", "").lower()

            # The contract intentionally carries the safety assertion
            # containsGroundTruth=false. That exact key is allowed; actual
            # ground-truth payload keys remain forbidden.
            if normalized != "containsgroundtruth":
                if any(
                    fragment in normalized
                    for fragment in _FORBIDDEN_KEY_FRAGMENTS
                ):
                    raise TelemetryIntegrityError(
                        f"Forbidden operational telemetry key: {key}"
                    )

            _assert_no_forbidden_keys(nested_value)

    elif isinstance(value, list):
        for item in value:
            _assert_no_forbidden_keys(item)


def _parse_utc(value: str) -> datetime:
    if not value.endswith("Z"):
        raise ValueError("timestamp must use UTC Z suffix")

    return datetime.fromisoformat(
        value[:-1] + "+00:00"
    )
