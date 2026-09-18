from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


_BACKEND_DIRECTORY = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    """Valores de runtime; los secretos viven fuera del control de versiones."""

    model_config = SettingsConfigDict(
        env_file=_BACKEND_DIRECTORY / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    app_environment: str = "development"
    database_url: str
    supabase_url: str
    supabase_anon_key: str
    cors_origins: str = "http://localhost:3000,http://localhost:5173,http://localhost:8080"
    sql_echo: bool = False

    @property
    def allowed_cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
