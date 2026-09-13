from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

from app.core.errors import BackendConfigurationError


class Settings(BaseSettings):
    """Runtime configuration for the USAR backend bridge."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_prefix="USAR_",
        extra="ignore",
    )

    missions_root: Path | None = None
    matlab_project_root: Path | None = None
    matlab_executable: Path | None = None

    # Comma-separated string is deliberately used here because it is easier
    # and less error-prone for Windows .env files than JSON-encoding a list.
    allowed_origins: str = (
        "http://localhost:5173,"
        "http://127.0.0.1:5173"
    )

    max_event_page_size: int = 500


    @property
    def resolved_matlab_project_root(self) -> Path:
        if self.matlab_project_root is not None:
            path = self.matlab_project_root.expanduser().resolve()
        elif self.missions_root is not None:
            # Expected layout: <MATLAB_ROOT>/Outputs/missions
            path = self.missions_root.expanduser().resolve().parent.parent
        else:
            raise BackendConfigurationError(
                "USAR_MATLAB_PROJECT_ROOT or USAR_MISSIONS_ROOT must be configured."
            )

        if not path.is_dir():
            raise BackendConfigurationError(f"MATLAB project root does not exist: {path}")

        if not (path / "Integration").is_dir():
            raise BackendConfigurationError(
                f"MATLAB project root does not contain Integration/: {path}"
            )

        return path

    @property
    def allowed_origin_list(self) -> list[str]:
        return [
            item.strip()
            for item in self.allowed_origins.split(",")
            if item.strip()
        ]

    @field_validator("max_event_page_size")
    @classmethod
    def validate_page_size(cls, value: int) -> int:
        if value < 1 or value > 5000:
            raise ValueError(
                "max_event_page_size must be between 1 and 5000"
            )
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
