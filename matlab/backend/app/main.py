from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.api.envelope import error_envelope
from app.api.errors import ApiError
from app.api.routes import router
from app.api.scenario_routes import router as scenario_router
from app.core.config import get_settings


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="USAR Mission Telemetry Backend",
        version="0.2.0",
        docs_url="/docs",
        redoc_url=None,
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origin_list,
        allow_credentials=False,
        allow_methods=["GET", "POST"],
        allow_headers=["Accept", "Content-Type"],
    )

    app.include_router(router)
    app.include_router(scenario_router)

    @app.exception_handler(ApiError)
    async def api_error_handler(
        request: Request,
        exc: ApiError,
    ) -> JSONResponse:
        _ = request
        return JSONResponse(
            status_code=exc.status_code,
            content=error_envelope(
                exc.code,
                exc.message,
            ),
        )

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        request: Request,
        exc: RequestValidationError,
    ) -> JSONResponse:
        _ = request
        return JSONResponse(
            status_code=422,
            content=error_envelope(
                "VALIDATION_ERROR",
                "The request parameters are invalid.",
            ),
        )

    @app.exception_handler(Exception)
    async def unhandled_error_handler(
        request: Request,
        exc: Exception,
    ) -> JSONResponse:
        _ = request
        _ = exc
        return JSONResponse(
            status_code=500,
            content=error_envelope(
                "INTERNAL_SERVER_ERROR",
                "The server could not complete the request.",
            ),
        )

    return app


app = create_app()
