from __future__ import annotations

import json
import os
import time
from pathlib import Path

import pytest

from app.core.errors import (
    BackendConfigurationError,
    MissionNotFoundError,
)
from app.telemetry.repository import MissionRepository


def test_unconfigured_repository_is_rejected():
    repository = MissionRepository(None)

    with pytest.raises(BackendConfigurationError):
        _ = repository.missions_root


def test_latest_mission_requires_telemetry(
    mission_root: Path,
):
    mission_root.mkdir(parents=True)

    (mission_root / "MISSION_OLD").mkdir()
    (mission_root / "not-a-mission").mkdir()

    repository = MissionRepository(mission_root)

    with pytest.raises(MissionNotFoundError):
        repository.latest_mission_dir()


def test_latest_mission_uses_newest_valid_folder(
    mission_root: Path,
):
    mission_root.mkdir(parents=True)

    older = mission_root / "MISSION_OLD"
    newer = mission_root / "MISSION_NEW"

    older.mkdir()
    newer.mkdir()

    (older / "telemetry.jsonl").write_text(
        "{}\n",
        encoding="utf-8",
    )
    (newer / "telemetry.jsonl").write_text(
        "{}\n",
        encoding="utf-8",
    )

    now = time.time()
    os.utime(older, (now - 10, now - 10))
    os.utime(newer, (now, now))

    repository = MissionRepository(mission_root)

    assert repository.latest_mission_dir() == newer


def test_json_artifact_requires_object(
    mission_dir: Path,
):
    path = mission_dir / "result.json"
    path.write_text(
        json.dumps([1, 2, 3]),
        encoding="utf-8",
    )

    with pytest.raises(Exception):
        MissionRepository.read_json_artifact(
            mission_dir,
            "result.json",
        )
