from datetime import datetime, timedelta, timezone

import pytest
import responses

from marky.services.polymarket import GammaClient, GammaUnavailable

BASE = "https://gamma-api.polymarket.com"


@pytest.fixture
def client() -> GammaClient:
    return GammaClient(base_url=BASE, timeout=5.0, max_retries=2)


@responses.activate
def test_public_search_returns_events(client: GammaClient) -> None:
    responses.get(
        f"{BASE}/public-search",
        json={
            "events": [
                {"id": "e1", "slug": "a", "title": "A", "commentsEnabled": True},
                {"id": "e2", "slug": "b", "title": "B", "commentsEnabled": False},
            ]
        },
        status=200,
    )
    r = client.public_search("openai")
    assert [e.id for e in r.events] == ["e1", "e2"]


@responses.activate
def test_get_events_passes_window_and_ids(client: GammaClient) -> None:
    captured: dict[str, list[str]] = {}

    def _callback(request):
        from urllib.parse import parse_qs, urlparse

        captured.update(parse_qs(urlparse(request.url).query))
        return (
            200,
            {"Content-Type": "application/json"},
            '[{"id":"e1","slug":"a","title":"A","commentsEnabled":true}]',
        )

    responses.add_callback(responses.GET, f"{BASE}/events", callback=_callback)

    start = datetime(2026, 4, 6, tzinfo=timezone.utc)
    end = datetime(2026, 4, 7, tzinfo=timezone.utc)
    events = client.get_events(ids=["e1", "e2"], start_date_min=start, end_date_max=end)
    assert len(events) == 1
    assert captured["id"] == ["e1", "e2"]
    assert captured["start_date_min"] == ["2026-04-06T00:00:00Z"]
    assert captured["end_date_max"] == ["2026-04-07T00:00:00Z"]


@responses.activate
def test_get_comments_returns_parsed_objects(client: GammaClient) -> None:
    payload = [
        {
            "id": "c1",
            "body": "hi",
            "createdAt": "2026-04-06T12:00:00Z",
            "parentEntityType": "Event",
            "parentEntityId": "e1",
        }
    ]
    responses.get(f"{BASE}/comments", json=payload, status=200)

    out = client.get_comments(parent_entity_type="Event", parent_entity_id="e1")
    assert len(out) == 1
    assert out[0].id == "c1"


@responses.activate
def test_iter_event_comments_paginates_until_short_page(client: GammaClient) -> None:
    page1 = [
        {
            "id": f"c{i}",
            "body": "hi",
            "createdAt": "2026-04-06T12:00:00Z",
            "parentEntityType": "Event",
            "parentEntityId": "e1",
        }
        for i in range(500)
    ]
    page2 = [
        {
            "id": "c500",
            "body": "hi",
            "createdAt": "2026-04-06T11:00:00Z",
            "parentEntityType": "Event",
            "parentEntityId": "e1",
        }
    ]
    # responses matches in registration order (FIFO).
    responses.get(f"{BASE}/comments", json=page1, status=200)
    responses.get(f"{BASE}/comments", json=page2, status=200)

    start = datetime(2026, 4, 6, tzinfo=timezone.utc)
    end = datetime(2026, 4, 7, tzinfo=timezone.utc)
    collected = list(client.iter_event_comments("e1", start, end))
    assert len(collected) == 501
    assert collected[0].id == "c0"
    assert collected[-1].id == "c500"


@responses.activate
def test_iter_event_comments_early_exit_on_window(client: GammaClient) -> None:
    in_window = [
        {
            "id": "c1",
            "body": "in",
            "createdAt": "2026-04-06T12:00:00Z",
            "parentEntityType": "Event",
            "parentEntityId": "e1",
        }
    ]
    before_window = [
        {
            "id": "c2",
            "body": "old",
            "createdAt": "2026-04-05T12:00:00Z",
            "parentEntityType": "Event",
            "parentEntityId": "e1",
        }
    ]
    responses.get(f"{BASE}/comments", json=in_window + before_window, status=200)

    start = datetime(2026, 4, 6, tzinfo=timezone.utc)
    end = start + timedelta(days=1)
    collected = list(client.iter_event_comments("e1", start, end))
    assert [c.id for c in collected] == ["c1"]


@responses.activate
def test_get_events_retries_on_429_then_succeeds(client: GammaClient) -> None:
    responses.get(f"{BASE}/events", json={"error": "rate limit"}, status=429)
    responses.get(
        f"{BASE}/events",
        json=[{"id": "e1", "slug": "a", "title": "A", "commentsEnabled": True}],
        status=200,
    )
    events = client.get_events(ids=["e1"])
    assert len(events) == 1


@responses.activate
def test_get_events_raises_after_exhausted_retries(client: GammaClient) -> None:
    # Use a callback so the same URL can be matched any number of times —
    # urllib3.Retry and tenacity compound, producing more HTTP calls than is
    # convenient to enumerate one-by-one.
    def _always_500(request):
        return (500, {"Content-Type": "application/json"}, '{"error":"boom"}')

    responses.add_callback(responses.GET, f"{BASE}/events", callback=_always_500)
    with pytest.raises(GammaUnavailable):
        client.get_events(ids=["e1"])
