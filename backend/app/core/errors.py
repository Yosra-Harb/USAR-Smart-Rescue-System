class BackendConfigurationError(RuntimeError):
    pass


class MissionNotFoundError(LookupError):
    pass


class MissionArtifactNotFoundError(LookupError):
    pass


class TelemetryIntegrityError(RuntimeError):
    pass


class MissionNotCompletedError(RuntimeError):
    pass
