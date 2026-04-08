from datetime import date

import boto3
import pytest
from moto import mock_aws

from marky.services.dynamo import DynamoClient, TasksRepository

TABLE = "marky-data"


@pytest.fixture
def dynamo_table():
    with mock_aws():
        client = boto3.client("dynamodb", region_name="us-east-1")
        client.create_table(
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
        client.get_waiter("table_exists").wait(TableName=TABLE)
        resource = boto3.resource("dynamodb", region_name="us-east-1")
        table = resource.Table(TABLE)
        table.put_item(
            Item={"Hash": "Tasks#2026-04-07", "Sort": "OpenAI GPT-5#2026-04-06"}
        )
        table.put_item(
            Item={"Hash": "Tasks#2026-04-07", "Sort": "Tesla robotaxi#2026-04-05"}
        )
        # Different day — should not be returned for 2026-04-07.
        table.put_item(
            Item={"Hash": "Tasks#2026-04-08", "Sort": "Other#2026-04-07"}
        )
        # Different entity type — should not be returned even on the same day.
        table.put_item(
            Item={"Hash": "Reports#2026-04-07", "Sort": "anything#2026-04-06"}
        )
        yield table


def test_tasks_repository_lists_tasks_for_date(dynamo_table) -> None:
    repo = TasksRepository(client=DynamoClient(region="us-east-1"), table_name=TABLE)
    tasks = repo.list_tasks_for_date(date(2026, 4, 7))
    topics = sorted(t.topic for t in tasks)
    assert topics == ["OpenAI GPT-5", "Tesla robotaxi"]
    assert all(t.task_date == date(2026, 4, 7) for t in tasks)


def test_tasks_repository_returns_empty_for_unknown_date(dynamo_table) -> None:
    repo = TasksRepository(client=DynamoClient(region="us-east-1"), table_name=TABLE)
    assert repo.list_tasks_for_date(date(2026, 1, 1)) == []


def test_tasks_repository_does_not_leak_other_entities(dynamo_table) -> None:
    """Reports#2026-04-07 must not appear when querying tasks for that date."""
    repo = TasksRepository(client=DynamoClient(region="us-east-1"), table_name=TABLE)
    tasks = repo.list_tasks_for_date(date(2026, 4, 7))
    assert all(t.raw_item["Hash"].startswith("Tasks#") for t in tasks)
