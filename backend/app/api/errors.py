"""Stable HTTP error envelopes for authentication and domain failures."""

from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict

from backend.app.application.auth_service import AuthenticationError
from backend.app.domain.errors import DomainError


class FieldError(BaseModel):
    """A safe field-level validation message."""

    model_config = ConfigDict(extra="forbid")

    field: str
    message: str


class ErrorResponse(BaseModel):
    """The common machine-readable API failure shape."""

    model_config = ConfigDict(extra="forbid")

    error_code: str
    message: str
    field_errors: list[FieldError] | None = None


class CsrfFailedError(AuthenticationError):
    """Raised before an unsafe request reaches an application mutation."""

    def __init__(self) -> None:
        super().__init__(
            "csrf_failed",
            "The request origin or CSRF token is not allowed.",
        )


_AUTH_STATUS_CODES = {
    "invalid_credentials": 401,
    "unauthorized": 401,
    "session_expired": 401,
    "forbidden": 403,
    "csrf_failed": 403,
}
_DOMAIN_STATUS_CODES = {
    "invalid_amount": 422,
    "no_beneficiaries": 422,
    "no_participants": 422,
    "invalid_participant_reference": 422,
    "contribution_mismatch": 422,
    "invalid_participant_name": 422,
    "duplicate_participant_name": 422,
    "invalid_description": 422,
    "invalid_settlement_policy": 422,
    "participant_in_use": 409,
    "not_found": 404,
    "persistence_corrupted": 500,
}


def error_status(error_code: str) -> int:
    """Map a stable machine code to its HTTP status."""

    return _AUTH_STATUS_CODES.get(
        error_code,
        _DOMAIN_STATUS_CODES.get(error_code, 422),
    )


def error_response(
    error_code: str,
    message: str,
    *,
    field_errors: list[FieldError] | None = None,
) -> JSONResponse:
    """Create a response with no exception internals or account data."""

    payload = ErrorResponse(
        error_code=error_code,
        message=message,
        field_errors=field_errors,
    )
    return JSONResponse(
        status_code=error_status(error_code),
        content=payload.model_dump(mode="json", exclude_none=True),
    )


def _expected_error_response(error: AuthenticationError | DomainError) -> JSONResponse:
    return error_response(error.error_code, str(error))


def register_error_handlers(app: FastAPI) -> FastAPI:
    """Install stable handlers on an application and return it for composition."""

    @app.exception_handler(AuthenticationError)
    async def authentication_error_handler(
        _request: Request, error: AuthenticationError
    ) -> JSONResponse:
        return _expected_error_response(error)

    @app.exception_handler(DomainError)
    async def domain_error_handler(
        _request: Request, error: DomainError
    ) -> JSONResponse:
        return _expected_error_response(error)

    @app.exception_handler(RequestValidationError)
    async def validation_error_handler(
        _request: Request, error: RequestValidationError
    ) -> JSONResponse:
        field_errors: list[FieldError] = []
        for item in error.errors():
            location = item.get("loc", ())
            field = ".".join(str(value) for value in location if value != "body")
            field_errors.append(
                FieldError(
                    field=field or "request",
                    message=str(item.get("msg", "Invalid request.")),
                )
            )
        return error_response(
            "invalid_request",
            "The request could not be validated.",
            field_errors=field_errors,
        )

    return app


__all__ = [
    "CsrfFailedError",
    "ErrorResponse",
    "FieldError",
    "error_response",
    "error_status",
    "register_error_handlers",
]
