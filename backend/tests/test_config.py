import logging

import pytest

from marky.config import Settings
from marky.logging_setup import configure_logging


def test_settings_reads_env(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("MARKY_POLYMARKET_RAW_DATA_S3_BUCKET", "my-bucket")
    monkeypatch.setenv("MARKY_DYNAMO_DATA_TABLE", "my-data")
    monkeypatch.setenv("MARKY_GAMMA_BASE_URL", "https://example.test")
    monkeypatch.setenv("MARKY_GAMMA_TIMEOUT_SECONDS", "30")
    monkeypatch.setenv("MARKY_GAMMA_MAX_RETRIES", "7")
    monkeypatch.setenv("MARKY_LOG_LEVEL", "DEBUG")
    monkeypatch.setenv("AWS_REGION", "eu-west-1")

    s = Settings()
    assert s.s3_bucket == "my-bucket"
    assert s.dynamo_data_table == "my-data"
    assert s.gamma_base_url == "https://example.test"
    assert s.gamma_timeout_seconds == 30
    assert s.gamma_max_retries == 7
    assert s.log_level == "DEBUG"
    assert s.aws_region == "eu-west-1"


def test_settings_defaults_when_only_required_set(monkeypatch: pytest.MonkeyPatch) -> None:
    for k in (
        "MARKY_DYNAMO_DATA_TABLE",
        "MARKY_GAMMA_BASE_URL",
        "MARKY_GAMMA_TIMEOUT_SECONDS",
        "MARKY_GAMMA_MAX_RETRIES",
        "MARKY_LOG_LEVEL",
    ):
        monkeypatch.delenv(k, raising=False)
    s = Settings()
    assert s.dynamo_data_table == "marky-data"
    assert s.gamma_base_url == "https://gamma-api.polymarket.com"
    assert s.gamma_timeout_seconds == 20
    assert s.gamma_max_retries == 5
    assert s.log_level == "INFO"


def test_configure_logging_sets_level() -> None:
    configure_logging("WARNING")
    assert logging.getLogger("marky").getEffectiveLevel() == logging.WARNING
    configure_logging("INFO")  # restore
