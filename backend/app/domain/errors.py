"""Stable domain error codes shared by monetary and expense rules."""

from enum import StrEnum


class ErrorCode(StrEnum):
    """Machine-readable codes for expected domain validation failures."""

    INVALID_AMOUNT = "invalid_amount"
    NO_BENEFICIARIES = "no_beneficiaries"
    NO_PARTICIPANTS = "no_participants"
    INVALID_PARTICIPANT_REFERENCE = "invalid_participant_reference"
    CONTRIBUTION_MISMATCH = "contribution_mismatch"
    INVALID_PARTICIPANT_NAME = "invalid_participant_name"
    DUPLICATE_PARTICIPANT_NAME = "duplicate_participant_name"
    PARTICIPANT_IN_USE = "participant_in_use"
    UNSUPPORTED_CURRENCY = "unsupported_currency"
    INVALID_RATE = "invalid_rate"
    CONVERSION_FAILED = "conversion_failed"


INVALID_AMOUNT = ErrorCode.INVALID_AMOUNT.value
NO_BENEFICIARIES = ErrorCode.NO_BENEFICIARIES.value
NO_PARTICIPANTS = ErrorCode.NO_PARTICIPANTS.value
INVALID_PARTICIPANT_REFERENCE = ErrorCode.INVALID_PARTICIPANT_REFERENCE.value
CONTRIBUTION_MISMATCH = ErrorCode.CONTRIBUTION_MISMATCH.value
INVALID_PARTICIPANT_NAME = ErrorCode.INVALID_PARTICIPANT_NAME.value
DUPLICATE_PARTICIPANT_NAME = ErrorCode.DUPLICATE_PARTICIPANT_NAME.value
PARTICIPANT_IN_USE = ErrorCode.PARTICIPANT_IN_USE.value
UNSUPPORTED_CURRENCY = ErrorCode.UNSUPPORTED_CURRENCY.value
INVALID_RATE = ErrorCode.INVALID_RATE.value
CONVERSION_FAILED = ErrorCode.CONVERSION_FAILED.value


class DomainError(Exception):
    """An expected domain failure with a stable machine-readable code."""

    def __init__(self, code: ErrorCode | str, message: str):
        self.code = str(code)
        self.message = message
        super().__init__(message)

    @property
    def error_code(self) -> str:
        """Expose the same code name used by the API error envelope."""

        return self.code


class InvalidAmountError(DomainError):
    """Raised when an amount is not a positive, exact decimal amount."""

    def __init__(
        self,
        message: str = (
            "Amount must be a positive decimal with at most two decimal places."
        ),
    ):
        super().__init__(ErrorCode.INVALID_AMOUNT, message)


class NoBeneficiariesError(DomainError):
    """Raised when an expense has no beneficiaries."""

    def __init__(
        self,
        message: str = "An expense requires at least one beneficiary.",
    ):
        super().__init__(ErrorCode.NO_BENEFICIARIES, message)


class NoParticipantsError(DomainError):
    """Raised when an expense has no participants."""

    def __init__(
        self,
        message: str = "An expense requires at least one participant.",
    ):
        super().__init__(ErrorCode.NO_PARTICIPANTS, message)


class InvalidParticipantReferenceError(DomainError):
    """Raised when an expense references a participant outside its group."""

    def __init__(
        self,
        message: str = "The expense references an invalid participant.",
    ):
        super().__init__(ErrorCode.INVALID_PARTICIPANT_REFERENCE, message)


class InvalidParticipantNameError(DomainError):
    """Raised when a participant name is blank after trimming."""

    def __init__(self, message: str = "Participant name must not be blank."):
        super().__init__(ErrorCode.INVALID_PARTICIPANT_NAME, message)


class DuplicateParticipantNameError(DomainError):
    """Raised when a normalized participant name already exists in the group."""

    def __init__(self, message: str = "That participant name is already in use."):
        super().__init__(ErrorCode.DUPLICATE_PARTICIPANT_NAME, message)


class ParticipantInUseError(DomainError):
    """Raised when a participant is referenced by historical expense data."""

    def __init__(
        self,
        message: str = "Participant is referenced by expenses; archive it instead.",
    ):
        super().__init__(ErrorCode.PARTICIPANT_IN_USE, message)


class ContributionMismatchError(DomainError):
    """Raised when contributor amounts do not equal the expense amount."""

    def __init__(
        self,
        message: str = "Contributor amounts must equal the expense amount.",
    ):
        super().__init__(ErrorCode.CONTRIBUTION_MISMATCH, message)


class UnsupportedCurrencyError(DomainError):
    def __init__(self, message: str = "Currency must be exactly USD, BOB, or EUR."):
        super().__init__(ErrorCode.UNSUPPORTED_CURRENCY, message)


class InvalidRateError(DomainError):
    def __init__(self, message: str = "Exchange rate must be a finite positive Decimal."):  # noqa: E501
        super().__init__(ErrorCode.INVALID_RATE, message)


class ConversionFailedError(DomainError):
    def __init__(self, message: str = "Money conversion could not be completed deterministically."):  # noqa: E501
        super().__init__(ErrorCode.CONVERSION_FAILED, message)
