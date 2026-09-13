from __future__ import annotations

from fastapi import APIRouter, status

from app.api.envelope import success_envelope
from app.api.errors import ApiError
from app.api.scenario_models import ScenarioRunRequest
from app.api.dependencies import get_scenario_run_manager
from app.core.errors import BackendConfigurationError
from app.scenario_runner import (
    ScenarioLaunchError,
    ScenarioRunConflictError,
)


router = APIRouter(prefix="/api/v1/scenario", tags=["scenario-control"])


@router.get("/presets")
def presets():
    return success_envelope(
        {
            "presets": [
                {"scenarioType": "Ideal", "label": "Ideal", "summary": "Low debris, low noise, strong vital signs."},
                {"scenarioType": "DenseDebris", "label": "Dense Debris", "summary": "High debris density and difficult access."},
                {"scenarioType": "HighNoise", "label": "High Noise", "summary": "Strong environmental noise challenge."},
                {"scenarioType": "DeepBurial", "label": "Deep Burial", "summary": "Deeply buried victim with high attenuation."},
                {"scenarioType": "MultipleVictims", "label": "Multiple Victims", "summary": "Five-victim search and rescue mission."},
                {"scenarioType": "WeakVitalSigns", "label": "Weak Vital Signs", "summary": "Low-strength vital-sign evidence."},
            ]
        }
    )


@router.post("/run", status_code=status.HTTP_202_ACCEPTED)
def run_scenario(request: ScenarioRunRequest):
    try:
        manager = get_scenario_run_manager()
        job = manager.start(request.to_matlab_contract())
        return success_envelope(job.snapshot())
    except ScenarioRunConflictError as exc:
        raise ApiError(409, "MISSION_ALREADY_RUNNING", str(exc))
    except BackendConfigurationError as exc:
        raise ApiError(503, "MATLAB_RUNNER_NOT_CONFIGURED", str(exc))
    except ScenarioLaunchError as exc:
        raise ApiError(500, "MATLAB_LAUNCH_FAILED", str(exc))


@router.get("/run/current")
def current_run():
    manager = get_scenario_run_manager()
    job = manager.current()
    return success_envelope(
        job.snapshot()
        if job is not None
        else {
            "runId": None,
            "status": "IDLE",
            "message": "No dashboard-started mission is active.",
            "processId": None,
            "returnCode": None,
            "missionId": None,
            "request": None,
            "requestPath": None,
            "logPath": None,
        }
    )
