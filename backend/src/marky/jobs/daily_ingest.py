"""Daily ingest job: tasks → Polymarket → S3."""
from __future__ import annotations

import logging
from datetime import date, datetime, timezone

from marky.config import Settings
from marky.logging_setup import configure_logging
from marky.models.tasks import FailedTask, RawDataPayload, RunResult, Task
from marky.services.dynamo import DynamoClient, TasksRepository
from marky.services.polymarket import GammaClient
from marky.services.s3 import RawDataRepository, S3Client

log = logging.getLogger("marky.jobs.daily_ingest")


def build_payload_for_task(task: Task, gamma: GammaClient) -> RawDataPayload:
    """Run the search → events → comments pipeline for a single task."""
    window = task.window()

    search = gamma.public_search(task.topic)
    event_ids = [e.id for e in search.events]
    if not event_ids:
        return RawDataPayload.from_parts(task=task, events=[], comments=[])

    events = gamma.get_events(
        ids=event_ids,
        start_date_min=window.start,
        end_date_max=window.end,
    )
    matched_count = len(events)
    targets = [e for e in events if e.comments_enabled]

    comments = []
    for event in targets:
        for comment in gamma.iter_event_comments(event.id, window.start, window.end):
            comments.append(comment)

    return RawDataPayload.from_parts(
        task=task,
        events=events,
        comments=comments,
        all_matched_event_count=matched_count,
    )


def run_daily_ingest(today: date | None = None) -> RunResult:
    settings = Settings()
    configure_logging(settings.log_level)

    if today is None:
        today = datetime.now(tz=timezone.utc).date()

    log.info("daily_ingest_start", extra={"run_date": today.isoformat()})

    gamma = GammaClient(
        base_url=settings.gamma_base_url,
        timeout=settings.gamma_timeout_seconds,
        max_retries=settings.gamma_max_retries,
    )
    tasks_repo = TasksRepository(
        client=DynamoClient(region=settings.aws_region),
        table_name=settings.dynamo_data_table,
    )
    raw_repo = RawDataRepository(
        client=S3Client(region=settings.aws_region),
        bucket=settings.s3_bucket,
    )

    tasks = tasks_repo.list_tasks_for_date(today)
    log.info("loaded_tasks", extra={"count": len(tasks), "date": today.isoformat()})

    succeeded: list[str] = []
    failed: list[FailedTask] = []

    for task in tasks:
        try:
            payload = build_payload_for_task(task, gamma)
            key = raw_repo.put_task_payload(payload)
            succeeded.append(key)
            log.info(
                "task_succeeded",
                extra={
                    "topic": task.topic,
                    "search_date": task.search_date.isoformat(),
                    "key": key,
                    "comments": payload.stats.comments_collected,
                },
            )
        except Exception as e:
            log.exception(
                "task_failed",
                extra={
                    "topic": task.topic,
                    "search_date": task.search_date.isoformat(),
                },
            )
            failed.append(
                FailedTask(task=task, error=str(e), error_type=type(e).__name__)
            )

    return RunResult(run_date=today, succeeded=succeeded, failed=failed)


def main() -> int:
    try:
        result = run_daily_ingest()
    except Exception:
        log.exception("daily_ingest_fatal")
        return 2
    print(result.summary_line())
    return result.exit_code()


if __name__ == "__main__":
    raise SystemExit(main())
