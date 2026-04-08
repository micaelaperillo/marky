import json
from datetime import date
from unittest.mock import patch

import boto3
import pytest
from moto import mock_aws

from marky.jobs import daily_ingest as job
from marky.models.polymarket import (
    PolymarketComment,
    PolymarketEvent,
    PublicSearchResponse,
)

TABLE = "marky-data"
BUCKET = "marky-polymarket-raw-data-10"


class FakeGamma:
    """In-memory fake of GammaClient for the integration test."""

    def __init__(self) -> None:
        self.search_calls: list[str] = []
        self.events_by_topic: dict[str, list[PolymarketEvent]] = {}
        self.comments_by_event: dict[str, list[PolymarketComment]] = {}
        self.fail_topics: set[str] = set()

    def public_search(self, term: str, limit_per_type: int = 50) -> PublicSearchResponse:
        self.search_calls.append(term)
        if term in self.fail_topics:
            raise RuntimeError(f"boom for {term}")
        return PublicSearchResponse(events=self.events_by_topic.get(term, []))

    def get_events(self, *, ids, start_date_min, end_date_max, limit=500):
        flat: list[PolymarketEvent] = []
        for evs in self.events_by_topic.values():
            for e in evs:
                if e.id in ids:
                    flat.append(e)
        return flat

    def iter_event_comments(self, event_id, window_start, window_end):
        for c in self.comments_by_event.get(event_id, []):
            if window_start <= c.created_at < window_end:
                yield c


@pytest.fixture
def aws_setup():
    with mock_aws():
        ddb = boto3.client("dynamodb", region_name="us-east-1")
        ddb.create_table(
            TableName=TABLE,
            AttributeDefinitions=[
                {"AttributeName": "Hash", "AttributeType": "S"},
                {"AttributeName": "Sort", "AttributeType": "S"},
            ],
            KeySchema=[
                {"AttributeName": "Hash", "KeyType": "HASH"},
                {"AttributeName": "Sort", "KeyType": "RANGE"},
            ],
            BillingMode="PAY_PER_REQUEST",
        )
        ddb.get_waiter("table_exists").wait(TableName=TABLE)
        table = boto3.resource("dynamodb", region_name="us-east-1").Table(TABLE)
        table.put_item(
            Item={"Hash": "TASKS#2026-04-07", "Sort": "OpenAI GPT-5#2026-04-06"}
        )
        table.put_item(
            Item={"Hash": "TASKS#2026-04-07", "Sort": "Tesla robotaxi#2026-04-06"}
        )
        s3 = boto3.client("s3", region_name="us-east-1")
        s3.create_bucket(Bucket=BUCKET)
        yield s3


def _make_event(eid: str) -> PolymarketEvent:
    return PolymarketEvent.model_validate(
        {"id": eid, "slug": eid, "title": eid, "commentsEnabled": True}
    )


def _make_comment(cid: str, eid: str, ts: str) -> PolymarketComment:
    return PolymarketComment.model_validate(
        {
            "id": cid,
            "body": "hi",
            "createdAt": ts,
            "parentEntityType": "Event",
            "parentEntityId": eid,
        }
    )


def test_daily_ingest_writes_one_object_per_task(
    aws_setup, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("MARKY_DYNAMO_DATA_TABLE", TABLE)
    monkeypatch.setenv("MARKY_POLYMARKET_RAW_DATA_S3_BUCKET", BUCKET)

    fake = FakeGamma()
    e1 = _make_event("e1")
    e2 = _make_event("e2")
    fake.events_by_topic = {"OpenAI GPT-5": [e1], "Tesla robotaxi": [e2]}
    fake.comments_by_event = {
        "e1": [_make_comment("c1", "e1", "2026-04-06T12:00:00Z")],
        "e2": [
            _make_comment("c2", "e2", "2026-04-06T11:00:00Z"),
            _make_comment("c3", "e2", "2026-04-05T11:00:00Z"),  # outside window
        ],
    }

    with patch.object(job, "GammaClient", return_value=fake):
        result = job.run_daily_ingest(today=date(2026, 4, 7))

    assert len(result.succeeded) == 2
    assert len(result.failed) == 0
    assert result.exit_code() == 0

    objs = aws_setup.list_objects_v2(Bucket=BUCKET, Prefix="raw-data/")
    keys = sorted(o["Key"] for o in objs["Contents"])
    assert keys == [
        "raw-data/openai-gpt-5/2026-04-06.json",
        "raw-data/tesla-robotaxi/2026-04-06.json",
    ]
    body = json.loads(
        aws_setup.get_object(Bucket=BUCKET, Key="raw-data/tesla-robotaxi/2026-04-06.json")[
            "Body"
        ].read()
    )
    assert body["stats"]["comments_collected"] == 1


def test_daily_ingest_isolates_failures(
    aws_setup, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setenv("MARKY_DYNAMO_DATA_TABLE", TABLE)
    monkeypatch.setenv("MARKY_POLYMARKET_RAW_DATA_S3_BUCKET", BUCKET)

    fake = FakeGamma()
    fake.events_by_topic = {"Tesla robotaxi": [_make_event("e2")]}
    fake.fail_topics = {"OpenAI GPT-5"}
    fake.comments_by_event = {"e2": []}

    with patch.object(job, "GammaClient", return_value=fake):
        result = job.run_daily_ingest(today=date(2026, 4, 7))

    assert len(result.succeeded) == 1
    assert len(result.failed) == 1
    assert result.failed[0].task.topic == "OpenAI GPT-5"
    assert result.exit_code() == 1
