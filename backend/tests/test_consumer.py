from __future__ import annotations

from pathlib import Path

import pytest

from app.core.errors import TelemetryIntegrityError
from app.telemetry.consumer import MissionTelemetryConsumer
from tests.conftest import (
    completed,
    started,
    step,
    track_created,
    write_record,
)


def test_incremental_refresh_reads_only_complete_lines(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())

    incomplete = step(sequence=1)
    write_record(telemetry, incomplete, newline=False)

    state = consumer.refresh(
        mission_dir.name,
        telemetry,
    )

    assert state.last_sequence == 0
    assert len(state.records) == 1

    with telemetry.open("ab") as stream:
        stream.write(b"\n")

    state = consumer.refresh(
        mission_dir.name,
        telemetry,
    )

    assert state.last_sequence == 1
    assert len(state.records) == 2


def test_consumer_builds_operational_state(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    for record in [
        started(),
        step(),
        track_created(),
        completed(),
    ]:
        write_record(telemetry, record)

    state = consumer.refresh(
        mission_dir.name,
        telemetry,
    )

    snapshot = state.snapshot()

    assert snapshot["status"] == "COMPLETED"
    assert snapshot["lastSequence"] == 3
    assert snapshot["activeTrackCount"] == 1
    assert snapshot["tracks"][0]["id"] == 1
    assert snapshot["containsGroundTruth"] is False
    assert snapshot["decision"] == "RESUME_SEARCH"


def test_sequence_gap_is_rejected(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(telemetry, step(sequence=2))

    with pytest.raises(
        TelemetryIntegrityError,
        match="sequence discontinuity",
    ):
        consumer.refresh(mission_dir.name, telemetry)


def test_backward_timestamp_is_rejected(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(
        telemetry,
        step(
            sequence=1,
            timestamp="2026-09-02T12:56:28.000Z",
        ),
    )

    with pytest.raises(
        TelemetryIntegrityError,
        match="timestamps moved backwards",
    ):
        consumer.refresh(mission_dir.name, telemetry)


def test_ground_truth_key_is_rejected(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    bad = started()
    bad["groundTruthPositions"] = [[1, 2]]

    write_record(telemetry, bad)

    with pytest.raises(
        TelemetryIntegrityError,
        match="Forbidden operational telemetry key",
    ):
        consumer.refresh(mission_dir.name, telemetry)


def test_ground_truth_flag_is_rejected(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    bad = started()
    bad["containsGroundTruth"] = True

    write_record(telemetry, bad)

    with pytest.raises(
        TelemetryIntegrityError,
        match="containsGroundTruth=false",
    ):
        consumer.refresh(mission_dir.name, telemetry)


def test_legacy_victim_confirmed_event_is_rejected(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())

    bad = track_created(sequence=1)
    bad["eventType"] = "VICTIM_CONFIRMED"

    write_record(telemetry, bad)

    with pytest.raises(
        TelemetryIntegrityError,
        match="Unsupported telemetry eventType",
    ):
        consumer.refresh(mission_dir.name, telemetry)


def test_incremental_event_query(
    mission_dir: Path,
    consumer: MissionTelemetryConsumer,
):
    telemetry = mission_dir / "telemetry.jsonl"

    for record in [
        started(),
        step(),
        track_created(),
        completed(),
    ]:
        write_record(telemetry, record)

    state = consumer.refresh(
        mission_dir.name,
        telemetry,
    )

    events = consumer.get_events(
        state,
        after_sequence=1,
        limit=2,
    )

    assert [item["sequence"] for item in events] == [2, 3]
