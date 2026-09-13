from __future__ import annotations

from functools import lru_cache

from app.core.config import get_settings
from app.telemetry.consumer import MissionTelemetryConsumer
from app.telemetry.repository import MissionRepository
from app.scenario_runner import ScenarioRunManager


@lru_cache
def get_repository() -> MissionRepository:
    settings = get_settings()
    return MissionRepository(settings.missions_root)


@lru_cache
def get_consumer() -> MissionTelemetryConsumer:
    return MissionTelemetryConsumer()


@lru_cache
def get_scenario_run_manager() -> ScenarioRunManager:
    return ScenarioRunManager(get_settings())
