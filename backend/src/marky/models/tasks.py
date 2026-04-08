"""Domain models for the daily ingest pipeline."""
from __future__ import annotations

from datetime import date, datetime, time, timedelta, timezone
from typing import Any, ClassVar

from pydantic import BaseModel, Field, computed_field, field_serializer

from marky.models.polymarket import PolymarketComment, PolymarketEvent
from marky.services.slugify import slugify


def _iso_z(dt: datetime) -> str:
    """Render a UTC datetime as `YYYY-MM-DDTHH:MM:SSZ`."""
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class TaskWindow(BaseModel):
    start: datetime
    end: datetime


class Task(BaseModel):
    """A single ingest task derived from one DynamoDB item."""

    task_date: date
    topic: str
    search_date: date
    raw_item: dict[str, Any] = Field(repr=False, exclude=True)

    HASH_PREFIX: ClassVar[str] = "Tasks#"

    @computed_field
    @property
    def topic_slug(self) -> str:
        return slugify(self.topic)

    @classmethod
    def from_dynamo_item(cls, item: dict[str, Any]) -> "Task":
        try:
            hash_value: str = item["Hash"]
            sort_value: str = item["Sort"]
        except KeyError as e:
            raise ValueError(f"missing required attribute: {e.args[0]}") from None

        if not hash_value.startswith(cls.HASH_PREFIX):
            raise ValueError(
                f"Hash does not start with {cls.HASH_PREFIX!r}: {hash_value!r}"
            )
        task_date_str = hash_value[len(cls.HASH_PREFIX) :]

        # Split on the LAST '#' so topics that contain '#' survive intact.
        idx = sort_value.rfind("#")
        if idx == -1:
            raise ValueError(
                f"Sort is not a composite '<Topic>#<SearchDate>': {sort_value!r}"
            )
        topic = sort_value[:idx]
        search_date_str = sort_value[idx + 1 :]

        return cls(
            task_date=date.fromisoformat(task_date_str),
            topic=topic,
            search_date=date.fromisoformat(search_date_str),
            raw_item=item,
        )

    def window(self) -> TaskWindow:
        start = datetime.combine(self.search_date, time.min, tzinfo=timezone.utc)
        return TaskWindow(start=start, end=start + timedelta(days=1))


class _PayloadTaskHeader(BaseModel):
    task_date: date
    topic: str
    topic_slug: str
    search_date: date
    window_start: datetime
    window_end: datetime

    @field_serializer("window_start", "window_end")
    def _ser_dt(self, dt: datetime) -> str:
        return _iso_z(dt)


class _PayloadStats(BaseModel):
    events_matched: int
    events_with_comments_enabled: int
    comments_collected: int


class RawDataPayload(BaseModel):
    """The JSON object written to S3 for one task."""
    task: _PayloadTaskHeader
    events: list[PolymarketEvent]
    comments: list[PolymarketComment]
    stats: _PayloadStats

    @classmethod
    def from_parts(
        cls,
        *,
        task: Task,
        events: list[PolymarketEvent],
        comments: list[PolymarketComment],
        all_matched_event_count: int | None = None,
    ) -> "RawDataPayload":
        window = task.window()
        return cls(
            task=_PayloadTaskHeader(
                task_date=task.task_date,
                topic=task.topic,
                topic_slug=task.topic_slug,
                search_date=task.search_date,
                window_start=window.start,
                window_end=window.end,
            ),
            events=events,
            comments=comments,
            stats=_PayloadStats(
                events_matched=all_matched_event_count
                if all_matched_event_count is not None
                else len(events),
                events_with_comments_enabled=sum(1 for e in events if e.comments_enabled),
                comments_collected=len(comments),
            ),
        )


class FailedTask(BaseModel):
    task: Task
    error: str
    error_type: str


class RunResult(BaseModel):
    run_date: date
    succeeded: list[str] = Field(default_factory=list)
    failed: list[FailedTask] = Field(default_factory=list)

    def summary_line(self) -> str:
        return (
            f"daily_ingest run_date={self.run_date.isoformat()} "
            f"succeeded={len(self.succeeded)} failed={len(self.failed)}"
        )

    def exit_code(self) -> int:
        return 1 if self.failed else 0
