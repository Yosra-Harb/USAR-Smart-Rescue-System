from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from app.core.errors import (
    BackendConfigurationError,
    MissionArtifactNotFoundError,
    MissionNotFoundError,
)


_MISSION_DIR_PATTERN = re.compile(r"^MISSION_[A-Za-z0-9_-]+$")


class MissionRepository:
    """Filesystem boundary for MATLAB mission artifacts.

    No API request is allowed to provide an arbitrary filesystem path.
    All reads are constrained to the configured missions root.
    """

    def __init__(self, missions_root: Path | None):
        self._missions_root = (
            missions_root.expanduser().resolve()
            if missions_root is not None
            else None
        )

    @property
    def missions_root(self) -> Path:
        if self._missions_root is None:
            raise BackendConfigurationError(
                "USAR_MISSIONS_ROOT is not configured."
            )

        if not self._missions_root.exists():
            raise BackendConfigurationError(
                f"Configured missions root does not exist: "
                f"{self._missions_root}"
            )

        if not self._missions_root.is_dir():
            raise BackendConfigurationError(
                f"Configured missions root is not a directory: "
                f"{self._missions_root}"
            )

        return self._missions_root

    def latest_mission_dir(self) -> Path:
        root = self.missions_root

        candidates: list[Path] = []

        for child in root.iterdir():
            if not child.is_dir():
                continue

            if not _MISSION_DIR_PATTERN.fullmatch(child.name):
                continue

            if not (child / "telemetry.jsonl").is_file():
                continue

            candidates.append(child)

        if not candidates:
            raise MissionNotFoundError(
                "No mission with telemetry.jsonl was found."
            )

        # MATLAB creates a new folder for each mission. Modification time is
        # the most useful source for "current" while keeping mission IDs opaque.
        return max(
            candidates,
            key=lambda path: (
                path.stat().st_mtime_ns,
                path.name,
            ),
        )

    @staticmethod
    def mission_id_from_dir(mission_dir: Path) -> str:
        return mission_dir.name

    @staticmethod
    def telemetry_path(mission_dir: Path) -> Path:
        path = mission_dir / "telemetry.jsonl"

        if not path.is_file():
            raise MissionArtifactNotFoundError(
                f"telemetry.jsonl is missing for {mission_dir.name}."
            )

        return path

    @staticmethod
    def read_json_artifact(
        mission_dir: Path,
        filename: str,
    ) -> dict[str, Any]:
        path = mission_dir / filename

        if not path.is_file():
            raise MissionArtifactNotFoundError(
                f"{filename} is not available for {mission_dir.name}."
            )

        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as exc:
            raise MissionArtifactNotFoundError(
                f"{filename} could not be read safely."
            ) from exc

        if not isinstance(payload, dict):
            raise MissionArtifactNotFoundError(
                f"{filename} must contain one JSON object."
            )

        return payload
