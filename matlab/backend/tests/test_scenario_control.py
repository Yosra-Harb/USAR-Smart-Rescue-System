from __future__ import annotations

from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from app.api.scenario_models import ScenarioRunRequest
from app.main import app


def test_custom_request_requires_all_effective_controls():
    with pytest.raises(ValueError):
        ScenarioRunRequest(
            scenarioType="Custom",
            numVictims=3,
        )


def test_preset_rejects_custom_overrides():
    with pytest.raises(ValueError):
        ScenarioRunRequest(
            scenarioType="Ideal",
            debrisDensity=0.5,
        )


def test_valid_custom_request_maps_to_matlab_contract():
    request = ScenarioRunRequest(
        scenarioType="Custom",
        randomSeed=731,
        numVictims=3,
        debrisDensity=0.5,
        noiseLevel=0.4,
        burialDepth=0.5,
        vitalStrength=0.6,
    )

    assert request.to_matlab_contract() == {
        "schemaVersion": "1.0",
        "scenarioType": "Custom",
        "randomSeed": 731,
        "numVictims": 3,
        "debrisDensity": 0.5,
        "noiseLevel": 0.4,
        "burialDepth": 0.5,
        "vitalStrength": 0.6,
    }


def test_presets_endpoint_lists_six_fixed_scenarios():
    with TestClient(app) as client:
        response = client.get("/api/v1/scenario/presets")

    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert len(body["data"]["presets"]) == 6


def test_run_endpoint_accepts_dashboard_request(monkeypatch):
    import app.api.scenario_routes as scenario_routes

    fake_job = SimpleNamespace(
        snapshot=lambda: {
            "runId": "RUN_TEST",
            "status": "STARTING_MATLAB",
            "message": "Starting MATLAB",
            "processId": 123,
            "returnCode": None,
            "missionId": None,
            "request": {"scenarioType": "Ideal"},
            "requestPath": "request.json",
            "logPath": "run.log",
        }
    )

    class FakeManager:
        def start(self, payload):
            assert payload["scenarioType"] == "Ideal"
            return fake_job

    monkeypatch.setattr(
        scenario_routes,
        "get_scenario_run_manager",
        lambda: FakeManager(),
    )

    with TestClient(app) as client:
        response = client.post(
            "/api/v1/scenario/run",
            json={"schemaVersion": "1.0", "scenarioType": "Ideal"},
        )

    assert response.status_code == 202
    assert response.json()["data"]["runId"] == "RUN_TEST"
