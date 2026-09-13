from __future__ import annotations

from datetime import datetime, timezone
from typing import Any


def success_envelope(data: Any) -> dict[str, Any]:
    return {
        "success": True,
        "data": data,
        "timestamp": datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z"),
        "version": "v1",
    }


def error_envelope(
    code: str,
    message: str,
) -> dict[str, Any]:
    return {
        "success": False,
        "error": {
            "code": code,
            "message": message,
        },
        "timestamp": datetime.now(timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z"),
        "version": "v1",
    }
