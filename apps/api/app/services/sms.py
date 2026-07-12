"""SMS delivery behind a provider interface.

MVP ships a console/mock provider (dev default) so the app runs with no SMS
credentials. The real Eskiz.uz provider is wired in Phase 5.
"""

from __future__ import annotations

import logging
from abc import ABC, abstractmethod

from app.core.config import settings

logger = logging.getLogger("sms")


class SmsProvider(ABC):
    @abstractmethod
    def send(self, phone: str, message: str) -> None: ...


class ConsoleSmsProvider(SmsProvider):
    """Prints the message to logs instead of sending a real SMS."""

    def send(self, phone: str, message: str) -> None:
        logger.info("[SMS -> %s] %s", phone, message)


class EskizSmsProvider(SmsProvider):
    """Placeholder for the real Eskiz.uz gateway (implemented in Phase 5)."""

    def send(self, phone: str, message: str) -> None:  # pragma: no cover
        raise NotImplementedError("Eskiz SMS provider is implemented in Phase 5")


def get_sms_provider() -> SmsProvider:
    if settings.SMS_PROVIDER == "eskiz":
        return EskizSmsProvider()
    return ConsoleSmsProvider()


def send_otp_sms(phone: str, code: str) -> None:
    get_sms_provider().send(phone, f"Admin Market tasdiqlash kodi: {code}")
