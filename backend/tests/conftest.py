"""Shared pytest fixtures and AWS env isolation for moto."""
import pytest


@pytest.fixture(autouse=True)
def _aws_env(monkeypatch: pytest.MonkeyPatch) -> None:
    """Force fake AWS creds so no test can accidentally hit real AWS.

    Individual tests may override any of these via their own ``monkeypatch``
    calls — pytest's monkeypatch is per-test, so the autouse defaults are
    safe to layer on.
    """
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_SESSION_TOKEN", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", "us-east-1")
    monkeypatch.setenv("AWS_REGION", "us-east-1")
    # Prevent pydantic-settings from picking up developer .env files.
    monkeypatch.setenv("MARKY_POLYMARKET_RAW_DATA_S3_BUCKET", "test-bucket")
