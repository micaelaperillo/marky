import json
from datetime import date

import boto3
import pytest
from moto import mock_aws

from marky.models.polymarket import PolymarketComment, PolymarketEvent
from marky.models.tasks import RawDataPayload, Task
from marky.services.s3 import RawDataRepository, S3Client

BUCKET = "marky-polymarket-raw-data-10"


@pytest.fixture
def s3_bucket():
    with mock_aws():
        client = boto3.client("s3", region_name="us-east-1")
        client.create_bucket(Bucket=BUCKET)
        yield client


def _make_payload() -> tuple[Task, RawDataPayload]:
    task = Task(
        task_date=date(2026, 4, 7),
        topic="OpenAI GPT-5",
        search_date=date(2026, 4, 6),
        raw_item={},
    )
    event = PolymarketEvent.model_validate(
        {"id": "e1", "slug": "a", "title": "A", "commentsEnabled": True}
    )
    comment = PolymarketComment.model_validate(
        {
            "id": "c1",
            "body": "hi",
            "createdAt": "2026-04-06T01:00:00Z",
            "parentEntityType": "Event",
            "parentEntityId": "e1",
        }
    )
    return task, RawDataPayload.from_parts(task=task, events=[event], comments=[comment])


def test_put_task_payload_writes_expected_key(s3_bucket) -> None:
    repo = RawDataRepository(client=S3Client(region="us-east-1"), bucket=BUCKET)
    _, payload = _make_payload()
    key = repo.put_task_payload(payload)
    assert key == "raw-data/openai-gpt-5/2026-04-06.json"

    obj = s3_bucket.get_object(Bucket=BUCKET, Key=key)
    assert obj["ContentType"] == "application/json"
    body = json.loads(obj["Body"].read())
    assert body["task"]["topic"] == "OpenAI GPT-5"
    assert body["stats"]["comments_collected"] == 1


def test_put_task_payload_overwrites_existing(s3_bucket) -> None:
    repo = RawDataRepository(client=S3Client(region="us-east-1"), bucket=BUCKET)
    _, payload = _make_payload()
    key1 = repo.put_task_payload(payload)
    key2 = repo.put_task_payload(payload)
    assert key1 == key2
    objs = s3_bucket.list_objects_v2(Bucket=BUCKET, Prefix="raw-data/")
    assert objs["KeyCount"] == 1
