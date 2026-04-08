"""DynamoDB client wrapper and TasksRepository business adapter."""
from __future__ import annotations

import logging
from collections.abc import Iterator
from datetime import date
from typing import Any

import boto3
from boto3.dynamodb.conditions import Key

from marky.models.tasks import Task

log = logging.getLogger("marky.services.dynamo")


class DynamoClient:
    """Generic boto3 DynamoDB resource wrapper. No business knowledge."""

    def __init__(self, region: str) -> None:
        self._resource = boto3.resource("dynamodb", region_name=region)

    def table(self, name: str):
        return self._resource.Table(name)

    def query(self, table_name: str, **kwargs: Any) -> Iterator[dict]:
        """Auto-paginating wrapper around DynamoDB Query."""
        table = self.table(table_name)
        last_evaluated: dict | None = None
        while True:
            params = dict(kwargs)
            if last_evaluated is not None:
                params["ExclusiveStartKey"] = last_evaluated
            response = table.query(**params)
            for item in response.get("Items", []):
                yield item
            last_evaluated = response.get("LastEvaluatedKey")
            if not last_evaluated:
                return


class TasksRepository:
    """Business adapter for the Tasks#... entity in `marky-data`.

    Owns the `"Tasks#"` partition-key prefix so the rest of the codebase
    can stay agnostic of the single-table layout.
    """

    HASH_PREFIX = "Tasks#"

    def __init__(self, client: DynamoClient, table_name: str) -> None:
        self._client = client
        self._table_name = table_name

    def _hash_for_date(self, task_date: date) -> str:
        return f"{self.HASH_PREFIX}{task_date.isoformat()}"

    def list_tasks_for_date(self, task_date: date) -> list[Task]:
        items = self._client.query(
            self._table_name,
            KeyConditionExpression=Key("Hash").eq(self._hash_for_date(task_date)),
        )
        out: list[Task] = []
        for item in items:
            try:
                out.append(Task.from_dynamo_item(item))
            except ValueError:
                log.exception(
                    "skipping malformed task item",
                    extra={"item_keys": list(item.keys())},
                )
        return out
