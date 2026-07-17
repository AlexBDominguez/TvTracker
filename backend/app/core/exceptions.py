import logging

import httpx
from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

logger = logging.getLogger("app")


def _error_response(code: int, message: str) -> JSONResponse:
    return JSONResponse(status_code=code, content={"error": message, "code": code})


async def http_exception_handler(request: Request, exc: StarletteHTTPException) -> JSONResponse:
    return _error_response(exc.status_code, exc.detail)


async def validation_exception_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    return _error_response(status.HTTP_422_UNPROCESSABLE_CONTENT, "Invalid request data")


async def external_service_exception_handler(
    request: Request, exc: httpx.HTTPError
) -> JSONResponse:
    logger.warning("External service call failed: %s", exc)
    return _error_response(
        status.HTTP_503_SERVICE_UNAVAILABLE, "Servicio externo no disponible"
    )


async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
    logger.exception("Unhandled error")
    return _error_response(status.HTTP_500_INTERNAL_SERVER_ERROR, "Internal server error")


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(StarletteHTTPException, http_exception_handler)
    app.add_exception_handler(RequestValidationError, validation_exception_handler)
    app.add_exception_handler(httpx.HTTPError, external_service_exception_handler)
    app.add_exception_handler(Exception, unhandled_exception_handler)
