from __future__ import annotations

import json
import os
import shutil
import subprocess
import threading
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Callable

from app.core.config import Settings
from app.core.errors import BackendConfigurationError


class ScenarioRunConflictError(RuntimeError):
    pass


class ScenarioLaunchError(RuntimeError):
    pass


@dataclass
class ScenarioRunJob:
    run_id: str
    request: dict[str, Any]
    request_path: Path
    log_path: Path
    started_epoch: float
    known_missions: set[str] = field(default_factory=set)
    status: str = "STARTING_MATLAB"
    process_id: int | None = None
    return_code: int | None = None
    mission_id: str | None = None
    message: str = "Starting MATLAB mission runner."

    def snapshot(self) -> dict[str, Any]:
        return {
            "runId": self.run_id,
            "status": self.status,
            "message": self.message,
            "processId": self.process_id,
            "returnCode": self.return_code,
            "missionId": self.mission_id,
            "request": self.request,
            "requestPath": str(self.request_path),
            "logPath": str(self.log_path),
        }


class ScenarioRunManager:
    """Starts one MATLAB mission at a time from a validated dashboard request."""

    def __init__(
        self,
        settings: Settings,
        *,
        popen_factory: Callable[..., subprocess.Popen] = subprocess.Popen,
    ) -> None:
        self._settings = settings
        self._popen_factory = popen_factory
        self._lock = threading.Lock()
        self._current: ScenarioRunJob | None = None

    def start(self, request: dict[str, Any]) -> ScenarioRunJob:
        with self._lock:
            if self._current is not None and self._current.status in {
                "STARTING_MATLAB",
                "RUNNING",
            }:
                raise ScenarioRunConflictError(
                    "A MATLAB mission is already running. Wait for it to finish before starting another one."
                )

            project_root = self._settings.resolved_matlab_project_root
            matlab_executable = self._resolve_matlab_executable()
            requests_dir = project_root / "Integration" / "DashboardRequests"
            requests_dir.mkdir(parents=True, exist_ok=True)

            run_id = "RUN_" + uuid.uuid4().hex[:12].upper()
            request_path = requests_dir / f"{run_id}.json"
            log_path = requests_dir / f"{run_id}.log"
            request_path.write_text(
                json.dumps(request, indent=2),
                encoding="utf-8",
            )

            known_missions = self._current_mission_names()
            job = ScenarioRunJob(
                run_id=run_id,
                request=request,
                request_path=request_path,
                log_path=log_path,
                started_epoch=time.time(),
                known_missions=known_missions,
            )

            expression = self._matlab_expression(
                project_root=project_root,
                request_path=request_path,
            )

            log_stream = log_path.open("wb")
            kwargs: dict[str, Any] = {
                "cwd": str(project_root),
                "stdout": log_stream,
                "stderr": subprocess.STDOUT,
            }

            if os.name == "nt":
                kwargs["creationflags"] = getattr(
                    subprocess,
                    "CREATE_NO_WINDOW",
                    0,
                )

            try:
                process = self._popen_factory(
                    [str(matlab_executable), "-batch", expression],
                    **kwargs,
                )
            except OSError as exc:
                log_stream.close()
                raise ScenarioLaunchError(
                    f"MATLAB could not be started: {exc}"
                ) from exc

            job.process_id = process.pid
            job.status = "STARTING_MATLAB"
            job.message = "MATLAB process started; waiting for mission telemetry."
            self._current = job

            watcher = threading.Thread(
                target=self._watch_process,
                args=(job, process, log_stream),
                daemon=True,
                name=f"usar-matlab-{run_id}",
            )
            watcher.start()
            return job

    def current(self) -> ScenarioRunJob | None:
        with self._lock:
            if self._current is None:
                return None

            self._refresh_mission_identity(self._current)
            return self._current

    def _watch_process(
        self,
        job: ScenarioRunJob,
        process: subprocess.Popen,
        log_stream,
    ) -> None:
        try:
            while process.poll() is None:
                with self._lock:
                    self._refresh_mission_identity(job)
                    if job.mission_id is not None:
                        job.status = "RUNNING"
                        job.message = "Mission telemetry is live."
                time.sleep(0.5)

            return_code = process.wait()
            with self._lock:
                self._refresh_mission_identity(job)
                job.return_code = return_code
                if return_code == 0:
                    job.status = "COMPLETED"
                    job.message = "MATLAB mission completed successfully."
                else:
                    job.status = "FAILED"
                    job.message = (
                        "MATLAB mission process failed. Review the run log for details."
                    )
        finally:
            log_stream.close()

    def _refresh_mission_identity(self, job: ScenarioRunJob) -> None:
        if job.mission_id is not None:
            return

        root = self._settings.missions_root
        if root is None or not root.exists():
            return

        candidates = [
            path
            for path in root.iterdir()
            if path.is_dir()
            and path.name.startswith("MISSION_")
            and path.name not in job.known_missions
            and (path / "telemetry.jsonl").is_file()
        ]

        if not candidates:
            return

        newest = max(
            candidates,
            key=lambda path: (path.stat().st_mtime_ns, path.name),
        )
        job.mission_id = newest.name

    def _current_mission_names(self) -> set[str]:
        root = self._settings.missions_root
        if root is None or not root.exists():
            return set()
        return {
            path.name
            for path in root.iterdir()
            if path.is_dir() and path.name.startswith("MISSION_")
        }

    def _resolve_matlab_executable(self) -> Path:
        configured = self._settings.matlab_executable
        if configured is not None:
            path = configured.expanduser()
            if path.is_file():
                return path.resolve()
            raise BackendConfigurationError(
                f"Configured MATLAB executable does not exist: {path}"
            )

        from_path = shutil.which("matlab")
        if from_path:
            return Path(from_path).resolve()

        if os.name == "nt":
            program_files = Path(os.environ.get("ProgramFiles", r"C:\Program Files"))
            matlab_root = program_files / "MATLAB"
            if matlab_root.is_dir():
                candidates = sorted(
                    matlab_root.glob("R*/bin/matlab.exe"),
                    reverse=True,
                )
                if candidates:
                    return candidates[0].resolve()

        raise BackendConfigurationError(
            "MATLAB executable was not found. Set USAR_MATLAB_EXECUTABLE to matlab.exe."
        )

    @staticmethod
    def _matlab_expression(
        *,
        project_root: Path,
        request_path: Path,
    ) -> str:
        integration_path = project_root / "Integration"
        integration_text = _matlab_quote(integration_path)
        request_text = _matlab_quote(request_path)
        return (
            f"addpath('{integration_text}'); "
            f"runDashboardScenarioRequest('{request_text}');"
        )


def _matlab_quote(path: Path) -> str:
    # MATLAB accepts forward slashes on Windows and doubled apostrophes.
    return path.resolve().as_posix().replace("'", "''")
