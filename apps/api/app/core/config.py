from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings, loaded from environment / .env.

    Nothing sensitive is hard-coded; everything comes from the environment.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ENV: str = "development"
    API_V1_PREFIX: str = "/api/v1"
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:8080"

    # Database — DATABASE_URL wins; otherwise assembled from parts.
    DATABASE_URL: str | None = None
    POSTGRES_USER: str = "adminmarket"
    POSTGRES_PASSWORD: str = "change-me-in-prod"
    POSTGRES_DB: str = "adminmarket"
    POSTGRES_HOST: str = "localhost"
    POSTGRES_PORT: int = 5432

    # JWT
    SECRET_KEY: str = "dev-secret-change-me"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # OTP
    OTP_TTL_MINUTES: int = 5
    OTP_LENGTH: int = 6

    # Providers
    SMS_PROVIDER: str = "console"
    ESKIZ_EMAIL: str = ""
    ESKIZ_PASSWORD: str = ""
    ESKIZ_FROM: str = "4546"

    STORAGE_PROVIDER: str = "local"
    MEDIA_ROOT: str = "media"
    MEDIA_URL: str = "/media"

    # Default commission % seeded into settings table.
    DEFAULT_COMMISSION_PERCENT: float = 5.0

    @property
    def database_url(self) -> str:
        if self.DATABASE_URL:
            return self.DATABASE_URL
        return (
            f"postgresql+psycopg://{self.POSTGRES_USER}:{self.POSTGRES_PASSWORD}"
            f"@{self.POSTGRES_HOST}:{self.POSTGRES_PORT}/{self.POSTGRES_DB}"
        )

    @property
    def cors_origins_list(self) -> list[str]:
        return [o.strip() for o in self.CORS_ORIGINS.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
