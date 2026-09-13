from __future__ import annotations

import json
from pathlib import Path

from fastapi.testclient import TestClient

from tests.conftest import (
    completed,
    started,
    step,
    track_created,
    write_record,
)


def test_health_endpoint(client: TestClient):
    response = client.get("/api/v1/health")

    assert response.status_code == 200

    payload = response.json()

    assert payload["success"] is True
    assert payload["data"]["status"] == "UP"
    assert payload["data"]["telemetrySchema"] == "1.1"


def test_state_endpoint_returns_safe_operational_snapshot(
    client: TestClient,
    mission_dir: Path,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(telemetry, step())
    write_record(telemetry, track_created())

    response = client.get(
        "/api/v1/mission/current/state"
    )

    assert response.status_code == 200

    data = response.json()["data"]

    assert data["missionId"] == mission_dir.name
    assert data["status"] == "RUNNING"
    assert data["lastSequence"] == 2
    assert data["containsGroundTruth"] is False
    assert data["activeTrackCount"] == 1


def test_incremental_telemetry_endpoint(
    client: TestClient,
    mission_dir: Path,
):
    telemetry = mission_dir / "telemetry.jsonl"

    for record in [
        started(),
        step(),
        track_created(),
        completed(),
    ]:
        write_record(telemetry, record)

    response = client.get(
        "/api/v1/mission/current/telemetry",
        params={
            "after_sequence": 1,
            "limit": 2,
        },
    )

    assert response.status_code == 200

    data = response.json()["data"]

    assert [
        item["sequence"]
        for item in data["events"]
    ] == [2, 3]

    assert data["nextSequence"] == 3
    assert data["hasMore"] is False


def test_result_blocked_until_mission_completed(
    client: TestClient,
    mission_dir: Path,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(telemetry, step())

    (mission_dir / "result.json").write_text(
        json.dumps(
            {
                "containsGroundTruth": False,
                "status": "COMPLETED",
            }
        ),
        encoding="utf-8",
    )

    response = client.get(
        "/api/v1/mission/current/result"
    )

    assert response.status_code == 409


def test_result_released_after_completion(
    client: TestClient,
    mission_dir: Path,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(telemetry, step())
    write_record(
        telemetry,
        completed(sequence=2),
    )

    (mission_dir / "result.json").write_text(
        json.dumps(
            {
                "containsGroundTruth": False,
                "status": "COMPLETED",
                "systemDetectionCount": 5,
            }
        ),
        encoding="utf-8",
    )

    response = client.get(
        "/api/v1/mission/current/result"
    )

    assert response.status_code == 200
    assert (
        response.json()["data"]["systemDetectionCount"]
        == 5
    )


def test_evaluation_blocked_while_running(
    client: TestClient,
    mission_dir: Path,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(telemetry, step())

    (mission_dir / "evaluation.json").write_text(
        json.dumps(
            {
                "evaluationOnly": True,
                "releasePolicy": "POST_MISSION_ONLY",
            }
        ),
        encoding="utf-8",
    )

    response = client.get(
        "/api/v1/mission/current/evaluation"
    )

    assert response.status_code == 409


def test_evaluation_released_post_mission(
    client: TestClient,
    mission_dir: Path,
):
    telemetry = mission_dir / "telemetry.jsonl"

    write_record(telemetry, started())
    write_record(
        telemetry,
        completed(sequence=1),
    )

    (mission_dir / "evaluation.json").write_text(
        json.dumps(
            {
                "evaluationOnly": True,
                "releasePolicy": "POST_MISSION_ONLY",
                "counts": {
                    "truePositives": 5,
                },
            }
        ),
        encoding="utf-8",
    )

    response = client.get(
        "/api/v1/mission/current/evaluation"
    )

    assert response.status_code == 200
    assert (
        response.json()["data"]["counts"]["truePositives"]
        == 5
    )


def test_missing_mission_uses_standard_error_envelope(
    client: TestClient,
):
    response = client.get(
        "/api/v1/mission/current/state"
    )

    assert response.status_code == 404

    payload = response.json()

    assert payload["success"] is False
    assert payload["error"]["code"] == "MISSION_NOT_FOUND"
    assert "detail" not in payload
