from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, model_validator


ScenarioType = Literal[
    "Ideal",
    "DenseDebris",
    "HighNoise",
    "DeepBurial",
    "MultipleVictims",
    "WeakVitalSigns",
    "Custom",
]


class ScenarioRunRequest(BaseModel):
    schemaVersion: Literal["1.0"] = "1.0"
    scenarioType: ScenarioType
    randomSeed: int | None = Field(default=None, ge=0, le=2**32 - 1)
    numVictims: int | None = Field(default=None, ge=1, le=20)
    debrisDensity: float | None = Field(default=None, ge=0, le=1)
    noiseLevel: float | None = Field(default=None, ge=0, le=1)
    burialDepth: float | None = Field(default=None, ge=0, le=1)
    vitalStrength: float | None = Field(default=None, ge=0, le=1)

    @model_validator(mode="after")
    def validate_scenario_contract(self):
        custom_fields = (
            "numVictims",
            "debrisDensity",
            "noiseLevel",
            "burialDepth",
            "vitalStrength",
        )

        if self.scenarioType == "Custom":
            missing = [
                name
                for name in custom_fields
                if getattr(self, name) is None
            ]
            if missing:
                raise ValueError(
                    "Custom scenarios require: " + ", ".join(missing)
                )
            return self

        overridden = [
            name
            for name in custom_fields
            if getattr(self, name) is not None
        ]
        if overridden:
            raise ValueError(
                "Preset scenarios cannot override: " + ", ".join(overridden)
            )
        return self

    def to_matlab_contract(self) -> dict:
        payload = self.model_dump(exclude_none=True)
        return payload
