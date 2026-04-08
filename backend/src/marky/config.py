"""Environment-driven configuration for the marky backend."""
from __future__ import annotations

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """All configuration is loaded from environment variables (or `.env`).

    Boto3 picks AWS credentials from its default chain — we do not surface them here.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    aws_region: str = Field(default="us-east-1", validation_alias="AWS_REGION")
    s3_bucket: str = Field(validation_alias="MARKY_POLYMARKET_RAW_DATA_S3_BUCKET")
    dynamo_data_table: str = Field(
        default="marky-data", validation_alias="MARKY_DYNAMO_DATA_TABLE"
    )
    gamma_base_url: str = Field(
        default="https://gamma-api.polymarket.com",
        validation_alias="MARKY_GAMMA_BASE_URL",
    )
    gamma_timeout_seconds: float = Field(
        default=20.0, validation_alias="MARKY_GAMMA_TIMEOUT_SECONDS"
    )
    gamma_max_retries: int = Field(default=5, validation_alias="MARKY_GAMMA_MAX_RETRIES")
    log_level: str = Field(default="INFO", validation_alias="MARKY_LOG_LEVEL")
