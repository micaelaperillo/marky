import pytest

from marky.services.slugify import slugify


@pytest.mark.parametrize(
    ("raw", "expected"),
    [
        ("OpenAI GPT-5", "openai-gpt-5"),
        ("  Tesla   robotaxi  ", "tesla-robotaxi"),
        ("AI/ML & Robotics!", "ai-ml-robotics"),
        ("---hyphens---", "hyphens"),
        ("Café déjà vu", "caf-d-j-vu"),
        ("123 numbers 456", "123-numbers-456"),
    ],
)
def test_slugify_cases(raw: str, expected: str) -> None:
    assert slugify(raw) == expected


def test_slugify_empty_string() -> None:
    assert slugify("") == ""


def test_slugify_only_punctuation() -> None:
    assert slugify("!!!---???") == ""
