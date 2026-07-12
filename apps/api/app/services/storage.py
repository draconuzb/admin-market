"""File storage behind a provider interface.

MVP saves uploads to local disk under MEDIA_ROOT and serves them via FastAPI
StaticFiles at MEDIA_URL. An S3-compatible provider can replace it later.
"""

from __future__ import annotations

import uuid
from abc import ABC, abstractmethod
from pathlib import Path

from app.core.config import settings


class StorageProvider(ABC):
    @abstractmethod
    def save(self, data: bytes, filename: str, subdir: str = "") -> str:
        """Persist bytes and return a public URL path."""


class LocalStorageProvider(StorageProvider):
    def __init__(self, root: str, url_prefix: str) -> None:
        self.root = Path(root)
        self.url_prefix = url_prefix.rstrip("/")

    def save(self, data: bytes, filename: str, subdir: str = "") -> str:
        ext = Path(filename).suffix.lower()
        name = f"{uuid.uuid4().hex}{ext}"
        target_dir = self.root / subdir if subdir else self.root
        target_dir.mkdir(parents=True, exist_ok=True)
        (target_dir / name).write_bytes(data)
        rel = f"{subdir}/{name}" if subdir else name
        return f"{self.url_prefix}/{rel}"


def get_storage_provider() -> StorageProvider:
    # Only "local" is implemented in MVP; S3 comes in v2.
    return LocalStorageProvider(settings.MEDIA_ROOT, settings.MEDIA_URL)
