import os
from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    PROJECT_NAME: str = "PawFinder"
    API_V1_STR: str = "/api"
    ENVIRONMENT: str = "development"

    # Database
    DATABASE_URL: str = "sqlite:///./pawfinder.db"
    TEST_DATABASE_URL: str = "sqlite:///:memory:"

    # JWT
    JWT_SECRET_KEY: str = "pawfinder-super-secret-development-key-change-in-production-2026"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:8000",
        "http://127.0.0.1",
        "http://10.0.2.2",  # Android emulator localhost loopback
        "*",
    ]

    # Supabase Storage
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_STORAGE_BUCKET: str = "pet-images"

    # Maps
    GOOGLE_MAPS_API_KEY: str = ""

    # Matching Algorithm Default Weights
    WEIGHT_ANIMAL_TYPE: float = 0.25
    WEIGHT_BREED_SIMILARITY: float = 0.15
    WEIGHT_COLOR_SIMILARITY: float = 0.15
    WEIGHT_LOCATION_PROXIMITY: float = 0.20
    WEIGHT_DATE_PROXIMITY: float = 0.10
    WEIGHT_FEATURES_DESCRIPTION: float = 0.15

    # Matching Thresholds
    MATCH_THRESHOLD_HIGH: float = 80.0
    MATCH_THRESHOLD_POSSIBLE: float = 60.0

    # Default discovery search radius (km)
    DEFAULT_SEARCH_RADIUS_KM: float = 10.0

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore"
    )


settings = Settings()

