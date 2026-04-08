from datetime import datetime, timezone

import pytest
from pydantic import ValidationError

from marky.models.polymarket import (
    PolymarketComment,
    PolymarketEvent,
    PolymarketMarket,
    PolymarketProfile,
    PolymarketTag,
    PublicSearchResponse,
)


def test_market_parses_outcome_prices_string() -> None:
    m = PolymarketMarket.model_validate(
        {
            "id": "1",
            "question": "Will X happen?",
            "description": "...",
            "outcomePrices": '["0.62", "0.38"]',
            "volume": "12345.67",
            "active": True,
            "closed": False,
        }
    )
    assert m.outcome_prices == [0.62, 0.38]
    assert m.volume == pytest.approx(12345.67)


def test_market_handles_missing_outcome_prices() -> None:
    m = PolymarketMarket.model_validate(
        {"id": "1", "question": "Q?", "active": True, "closed": False}
    )
    assert m.outcome_prices == []
    assert m.volume == 0.0


def test_market_handles_malformed_outcome_prices() -> None:
    m = PolymarketMarket.model_validate(
        {
            "id": "1",
            "question": "Q?",
            "outcomePrices": "not-json",
            "active": True,
            "closed": False,
        }
    )
    assert m.outcome_prices == []


def test_event_parses_nested_tags_and_dates() -> None:
    e = PolymarketEvent.model_validate(
        {
            "id": "evt-1",
            "slug": "openai-gpt5",
            "title": "OpenAI GPT-5 launch",
            "description": "desc",
            "startDate": "2026-04-01T00:00:00Z",
            "endDate":   "2026-05-01T00:00:00Z",
            "commentsEnabled": True,
            "tags": [{"id": "22", "label": "Tech", "slug": "tech"}],
            "markets": [],
        }
    )
    assert e.id == "evt-1"
    assert e.start_date == datetime(2026, 4, 1, tzinfo=timezone.utc)
    assert e.end_date == datetime(2026, 5, 1, tzinfo=timezone.utc)
    assert e.comments_enabled is True
    assert e.tags == [PolymarketTag(id="22", label="Tech", slug="tech")]


def test_event_tolerates_unknown_fields() -> None:
    e = PolymarketEvent.model_validate(
        {
            "id": "evt-1",
            "slug": "x",
            "title": "x",
            "commentsEnabled": False,
            "someFutureField": "ignored",
        }
    )
    assert e.comments_enabled is False


def test_event_requires_id() -> None:
    with pytest.raises(ValidationError):
        PolymarketEvent.model_validate({"slug": "x", "title": "x"})


def test_comment_parses_profile_and_dates() -> None:
    c = PolymarketComment.model_validate(
        {
            "id": "c1",
            "body": "Hello",
            "createdAt": "2026-04-06T13:24:11Z",
            "parentEntityType": "Event",
            "parentEntityId": "evt-1",
            "parentCommentID": None,
            "profile": {
                "userId": "u1",
                "displayName": "Alice",
                "pseudonym": "alice42",
            },
            "reactionCount": 3,
            "reportCount": 0,
        }
    )
    assert c.id == "c1"
    assert c.body == "Hello"
    assert c.created_at == datetime(2026, 4, 6, 13, 24, 11, tzinfo=timezone.utc)
    assert c.parent_entity_id == "evt-1"
    assert c.parent_comment_id is None
    assert c.profile == PolymarketProfile(user_id="u1", display_name="Alice", pseudonym="alice42")
    assert c.reaction_count == 3


def test_public_search_response_extracts_events() -> None:
    payload = {
        "events": [
            {"id": "e1", "slug": "a", "title": "A", "commentsEnabled": True},
            {"id": "e2", "slug": "b", "title": "B", "commentsEnabled": False},
        ],
        "markets": [],
        "profiles": [],
    }
    r = PublicSearchResponse.model_validate(payload)
    assert [e.id for e in r.events] == ["e1", "e2"]
