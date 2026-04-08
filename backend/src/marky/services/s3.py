"""S3 client wrapper and RawDataRepository business adapter."""
from __future__ import annotations

import logging

import boto3

from marky.models.tasks import RawDataPayload

log = logging.getLogger("marky.services.s3")


class S3Client:
    """Generic boto3 S3 client wrapper. No business knowledge."""

    def __init__(self, region: str) -> None:
        self._client = boto3.client("s3", region_name=region)

    def put_object(
        self,
        bucket: str,
        key: str,
        body: bytes,
        content_type: str = "application/octet-stream",
    ) -> None:
        self._client.put_object(
            Bucket=bucket, Key=key, Body=body, ContentType=content_type
        )


class RawDataRepository:
    """Business adapter for the `raw-data/` prefix in the polymarket bucket."""

    PREFIX = "raw-data"

    def __init__(self, client: S3Client, bucket: str) -> None:
        self._client = client
        self._bucket = bucket

    def _key_for(self, payload: RawDataPayload) -> str:
        return (
            f"{self.PREFIX}/{payload.task.topic_slug}/"
            f"{payload.task.search_date.isoformat()}.json"
        )

    def put_task_payload(self, payload: RawDataPayload) -> str:
        key = self._key_for(payload)
        body = payload.model_dump_json().encode("utf-8")
        self._client.put_object(
            bucket=self._bucket,
            key=key,
            body=body,
            content_type="application/json",
        )
        log.info("raw_data_put", extra={"bucket": self._bucket, "key": key, "bytes": len(body)})
        return key
