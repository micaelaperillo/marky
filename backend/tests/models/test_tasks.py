from datetime import date, datetime, timezone

import pytest

from marky.models.polymarket import PolymarketComment, PolymarketEvent
from marky.models.tasks import (
    FailedTask,
    RawDataPayload,
    RunResult,
    Task,
    TaskWindow,
)


def test_task_from_dynamo_item_simple() -> None:
    item = {
        "PK": "TASKS#2026-04-07",
        "SK": "OpenAI GPT-5#2026-04-06",
    }
    t = Task.from_dynamo_item(item)
    assert t.task_date == date(2026, 4, 7)
    assert t.topic == "OpenAI GPT-5"
    assert t.search_date == date(2026, 4, 6)
    assert t.topic_slug == "openai-gpt-5"
    assert t.raw_item == item


def test_task_from_dynamo_item_topic_with_hash() -> None:
    item = {
        "PK": "TASKS#2026-04-07",
        "SK": "C#  vs  F##2026-04-06",
    }
    t = Task.from_dynamo_item(item)
    assert t.topic == "C#  vs  F#"
    assert t.search_date == date(2026, 4, 6)
    assert t.topic_slug == "c-vs-f"


def test_task_from_dynamo_item_invalid_sort_raises() -> None:
    with pytest.raises(ValueError, match="SK"):
        Task.from_dynamo_item({"PK": "TASKS#2026-04-07", "SK": "no-hash"})


def test_task_from_dynamo_item_invalid_hash_raises() -> None:
    with pytest.raises(ValueError, match="PK"):
        Task.from_dynamo_item({"PK": "Reports#2026-04-07", "SK": "x#2026-04-06"})


def test_task_window_is_half_open_utc() -> None:
    t = Task(
        task_date=date(2026, 4, 7),
        topic="OpenAI GPT-5",
        search_date=date(2026, 4, 6),
        raw_item={},
    )
    w = t.window()
    assert w.start == datetime(2026, 4, 6, 0, 0, 0, tzinfo=timezone.utc)
    assert w.end == datetime(2026, 4, 7, 0, 0, 0, tzinfo=timezone.utc)


def test_raw_data_payload_serializes_with_lists() -> None:
    task = Task(
        task_date=date(2026, 4, 7),
        topic="X",
        search_date=date(2026, 4, 6),
        raw_item={},
    )
    event = PolymarketEvent.model_validate(
        {"id": "e1", "slug": "x", "title": "X", "commentsEnabled": True}
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
    payload = RawDataPayload.from_parts(task=task, events=[event], comments=[comment])
    dumped = payload.model_dump(mode="json")
    assert dumped["task"]["topic_slug"] == "x"
    assert dumped["task"]["window_start"] == "2026-04-06T00:00:00Z"
    assert dumped["task"]["window_end"] == "2026-04-07T00:00:00Z"
    assert dumped["stats"] == {
        "events_matched": 1,
        "events_with_comments_enabled": 1,
        "comments_collected": 1,
    }
    assert len(dumped["events"]) == 1
    assert len(dumped["comments"]) == 1


def test_run_result_summary_line_and_exit_code() -> None:
    task = Task(
        task_date=date(2026, 4, 7),
        topic="X",
        search_date=date(2026, 4, 6),
        raw_item={},
    )
    failed = FailedTask(task=task, error="boom", error_type="RuntimeError")
    rr = RunResult(run_date=date(2026, 4, 7), succeeded=["k1"], failed=[failed])
    line = rr.summary_line()
    assert "2026-04-07" in line
    assert "succeeded=1" in line
    assert "failed=1" in line
    assert rr.exit_code() == 1


def test_run_result_exit_code_zero_when_no_failures() -> None:
    rr = RunResult(run_date=date(2026, 4, 7), succeeded=["k1"], failed=[])
    assert rr.exit_code() == 0
