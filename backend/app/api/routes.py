from __future__ import annotations

from fastapi import APIRouter, Query

from app.api.dependencies import get_consumer, get_repository
from app.api.envelope import success_envelope
from app.api.errors import ApiError
from app.core.config import get_settings
from app.core.errors import (
    BackendConfigurationError,
    MissionArtifactNotFoundError,
    MissionNotCompletedError,
    MissionNotFoundError,
    TelemetryIntegrityError,
)


router = APIRouter(prefix="/api/v1")


def _load_current():
    repository = get_repository()
    consumer = get_consumer()

    mission_dir = repository.latest_mission_dir()
    mission_id = repository.mission_id_from_dir(mission_dir)
    telemetry_path = repository.telemetry_path(mission_dir)
    state = consumer.refresh(mission_id, telemetry_path)

    return repository, consumer, mission_dir, state


@router.get("/health")
def health():
    settings = get_settings()

    configured = settings.missions_root is not None

    return success_envelope(
        {
            "service": "usar-backend-telemetry-bridge",
            "status": "UP",
            "missionsRootConfigured": configured,
            "telemetrySchema": "1.1",
        }
    )


@router.get("/mission/current/state")
def current_state():
    try:
        _, _, _, state = _load_current()
        return success_envelope(state.snapshot())
    except BackendConfigurationError as exc:
        raise _http_error(503, "BACKEND_NOT_CONFIGURED", str(exc))
    except MissionNotFoundError as exc:
        raise _http_error(404, "MISSION_NOT_FOUND", str(exc))
    except TelemetryIntegrityError as exc:
        raise _http_error(409, "TELEMETRY_INTEGRITY_ERROR", str(exc))


@router.get("/mission/current/telemetry")
def current_telemetry(
    after_sequence: int = Query(default=-1, ge=-1),
    limit: int = Query(default=250, ge=1),
):
    settings = get_settings()

    if limit > settings.max_event_page_size:
        raise _http_error(
            422,
            "EVENT_PAGE_TOO_LARGE",
            f"limit must be <= {settings.max_event_page_size}.",
        )

    try:
        _, consumer, _, state = _load_current()
        events = consumer.get_events(
            state,
            after_sequence=after_sequence,
            limit=limit,
        )

        next_sequence = (
            int(events[-1]["sequence"])
            if events
            else after_sequence
        )

        return success_envelope(
            {
                "missionId": state.mission_id,
                "afterSequence": after_sequence,
                "nextSequence": next_sequence,
                "lastAvailableSequence": state.last_sequence,
                "hasMore": (
                    next_sequence < state.last_sequence
                ),
                "events": events,
            }
        )
    except BackendConfigurationError as exc:
        raise _http_error(503, "BACKEND_NOT_CONFIGURED", str(exc))
    except MissionNotFoundError as exc:
        raise _http_error(404, "MISSION_NOT_FOUND", str(exc))
    except TelemetryIntegrityError as exc:
        raise _http_error(409, "TELEMETRY_INTEGRITY_ERROR", str(exc))


@router.get("/mission/current/result")
def current_result():
    try:
        repository, _, mission_dir, state = _load_current()

        if state.status != "COMPLETED":
            raise MissionNotCompletedError(
                "Final result is available only after MISSION_COMPLETED."
            )

        payload = repository.read_json_artifact(
            mission_dir,
            "result.json",
        )

        if payload.get("containsGroundTruth") is not False:
            raise TelemetryIntegrityError(
                "result.json violated the operational ground-truth boundary."
            )

        return success_envelope(payload)
    except BackendConfigurationError as exc:
        raise _http_error(503, "BACKEND_NOT_CONFIGURED", str(exc))
    except MissionNotFoundError as exc:
        raise _http_error(404, "MISSION_NOT_FOUND", str(exc))
    except MissionNotCompletedError as exc:
        raise _http_error(409, "MISSION_NOT_COMPLETED", str(exc))
    except MissionArtifactNotFoundError as exc:
        raise _http_error(404, "RESULT_NOT_AVAILABLE", str(exc))
    except TelemetryIntegrityError as exc:
        raise _http_error(409, "RESULT_INTEGRITY_ERROR", str(exc))


@router.get("/mission/current/evaluation")
def current_evaluation():
    """Evaluation is deliberately unavailable until mission completion."""

    try:
        repository, _, mission_dir, state = _load_current()

        if state.status != "COMPLETED":
            raise MissionNotCompletedError(
                "Evaluation is POST_MISSION_ONLY."
            )

        payload = repository.read_json_artifact(
            mission_dir,
            "evaluation.json",
        )

        if payload.get("evaluationOnly") is not True:
            raise TelemetryIntegrityError(
                "evaluation.json must declare evaluationOnly=true."
            )

        if payload.get("releasePolicy") != "POST_MISSION_ONLY":
            raise TelemetryIntegrityError(
                "evaluation.json has an invalid releasePolicy."
            )

        return success_envelope(payload)
    except BackendConfigurationError as exc:
        raise _http_error(503, "BACKEND_NOT_CONFIGURED", str(exc))
    except MissionNotFoundError as exc:
        raise _http_error(404, "MISSION_NOT_FOUND", str(exc))
    except MissionNotCompletedError as exc:
        raise _http_error(409, "MISSION_NOT_COMPLETED", str(exc))
    except MissionArtifactNotFoundError as exc:
        raise _http_error(404, "EVALUATION_NOT_AVAILABLE", str(exc))
    except TelemetryIntegrityError as exc:
        raise _http_error(409, "EVALUATION_INTEGRITY_ERROR", str(exc))


def _http_error(
    status_code: int,
    code: str,
    message: str,
) -> ApiError:
    return ApiError(
        status_code=status_code,
        code=code,
        message=message,
    )
