from __future__ import annotations

import json
from pathlib import Path
from typing import Any

import pytest
from fastapi.testclient import TestClient

from app.api.dependencies import (
    get_consumer,
    get_repository,
)
from app.core.config import get_settings
from app.main import app
from app.telemetry.consumer import MissionTelemetryConsumer
from app.telemetry.repository import MissionRepository


@pytest.fixture
def mission_root(tmp_path: Path) -> Path:
    return tmp_path / "missions"


@pytest.fixture
def mission_dir(mission_root: Path) -> Path:
    path = mission_root / "MISSION_TEST_S284"
    path.mkdir(parents=True)
    return path


@pytest.fixture
def repository(mission_root: Path) -> MissionRepository:
    mission_root.mkdir(parents=True, exist_ok=True)
    return MissionRepository(mission_root)


@pytest.fixture
def consumer() -> MissionTelemetryConsumer:
    return MissionTelemetryConsumer()


@pytest.fixture
def client(
    repository: MissionRepository,
    consumer: MissionTelemetryConsumer,
):
    app.dependency_overrides = {}

    # routes use cached functions directly rather than Depends, therefore
    # replace their cache contents for test isolation.
    get_repository.cache_clear()
    get_consumer.cache_clear()
    get_settings.cache_clear()

    import app.api.dependencies as dependencies

    dependencies.get_repository.cache_clear()
    dependencies.get_consumer.cache_clear()

    # Monkeypatch via function cache by temporarily replacing module funcs.
    original_repo = dependencies.get_repository
    original_consumer = dependencies.get_consumer

    dependencies.get_repository = lambda: repository
    dependencies.get_consumer = lambda: consumer

    import app.api.routes as routes

    original_routes_repo = routes.get_repository
    original_routes_consumer = routes.get_consumer
    routes.get_repository = lambda: repository
    routes.get_consumer = lambda: consumer

    try:
        with TestClient(app) as test_client:
            yield test_client
    finally:
        dependencies.get_repository = original_repo
        dependencies.get_consumer = original_consumer
        routes.get_repository = original_routes_repo
        routes.get_consumer = original_routes_consumer


def write_record(
    path: Path,
    record: dict[str, Any],
    *,
    newline: bool = True,
) -> None:
    with path.open("ab") as stream:
        payload = json.dumps(
            record,
            separators=(",", ":"),
        ).encode("utf-8")

        stream.write(payload)

        if newline:
            stream.write(b"\n")


def started(
    mission_id: str = "MISSION_TEST_S284",
    sequence: int = 0,
) -> dict[str, Any]:
    return {
        "schemaVersion": "1.1",
        "contractType": "mission-telemetry",
        "eventType": "MISSION_STARTED",
        "missionId": mission_id,
        "sequence": sequence,
        "timestampUtc": "2026-09-02T12:56:29.000Z",
        "containsGroundTruth": False,
        "status": "RUNNING",
        "scenario": {
            "scenarioType": "Custom",
            "randomSeed": 284,
            "gridSize": [50, 50],
            "numVictims": 5,
            "debrisDensity": 0.75,
            "noiseLevel": 0.60,
            "burialDepth": 0.80,
            "vitalStrength": 0.30,
        },
    }


def step(
    mission_id: str = "MISSION_TEST_S284",
    sequence: int = 1,
    timestamp: str = "2026-09-02T12:56:30.000Z",
) -> dict[str, Any]:
    return {
        "schemaVersion": "1.1",
        "contractType": "mission-telemetry",
        "eventType": "STEP",
        "missionId": mission_id,
        "sequence": sequence,
        "timestampUtc": timestamp,
        "containsGroundTruth": False,
        "probe": {
            "id": 1,
            "position": {
                "row": 50,
                "column": 1,
                "x": 1,
                "y": 50,
            },
            "state": "SEARCHING",
            "currentStep": 1,
            "coverage": 0.01,
        },
        "sensors": {
            "quality": 0.8,
            "radar": {
                "normalized": 0.2,
                "physical": 0.3,
                "unit": "a.u.",
                "reliability": 0.9,
            },
            "thermal": {
                "normalized": 0.3,
                "physical": 35.8,
                "unit": "degC",
                "reliability": 0.8,
            },
            "acoustic": {
                "normalized": 0.1,
                "physical": 0.2,
                "unit": "a.u.",
                "reliability": 0.7,
            },
        },
        "fusion": {
            "score": 0.22,
            "confidence": 0.80,
            "weights": {
                "radar": 0.4,
                "thermal": 0.35,
                "acoustic": 0.25,
            },
        },
        "localization": {
            "isVictimDetected": False,
            "estimatedPosition": {
                "row": [],
                "column": [],
                "x": [],
                "y": [],
            },
            "confidence": [],
            "sourceType": "UNKNOWN",
            "method": "UNKNOWN",
            "posteriorProbability": [],
        },
        "vitality": {
            "isVictimDetected": False,
            "vitalityIndex": [],
            "condition": "UNKNOWN",
            "temporalStability": [],
        },
        "priority": {
            "score": [],
            "level": "UNKNOWN",
            "medicalSeverity": [],
        },
        "decision": "RESUME_SEARCH",
        "activeTrackCount": 0,
        "newTracks": [],
    }


def track_created(
    mission_id: str = "MISSION_TEST_S284",
    sequence: int = 2,
) -> dict[str, Any]:
    record = step(
        mission_id=mission_id,
        sequence=sequence,
        timestamp="2026-09-02T12:56:31.000Z",
    )
    record["eventType"] = "VICTIM_TRACK_CREATED"
    record["activeTrackCount"] = 1
    record["newTracks"] = [
        {
            "id": 1,
            "estimatedPosition": {
                "row": 36,
                "column": 8,
                "x": 8,
                "y": 36,
            },
            "vitalityIndex": 0.39,
            "medicalSeverity": 0.61,
            "priorityScore": 0.63,
            "priorityLevel": "HIGH",
            "rescueRank": 1,
        }
    ]
    return record


def completed(
    mission_id: str = "MISSION_TEST_S284",
    sequence: int = 3,
) -> dict[str, Any]:
    return {
        "schemaVersion": "1.1",
        "contractType": "mission-telemetry",
        "eventType": "MISSION_COMPLETED",
        "missionId": mission_id,
        "sequence": sequence,
        "timestampUtc": "2026-09-02T12:56:32.000Z",
        "containsGroundTruth": False,
        "status": "COMPLETED",
        "summary": {
            "systemDetectionCount": 5,
            "fusionHistorySize": 2133,
            "maximumFusionScore": 0.22846,
            "meanFusionScore": 0.030239,
        },
    }
