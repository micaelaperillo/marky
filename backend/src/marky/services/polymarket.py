"""Typed wrapper around the Polymarket Gamma API."""
from __future__ import annotations

import logging
from collections.abc import Iterator
from datetime import datetime, timezone
from typing import Any

import requests
from requests.adapters import HTTPAdapter
from tenacity import (
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_random_exponential,
)
from urllib3.util.retry import Retry

from marky.models.polymarket import (
    PolymarketComment,
    PolymarketEvent,
    PublicSearchResponse,
)

log = logging.getLogger("marky.services.polymarket")


class GammaError(Exception):
    """Base error for Gamma client failures."""


class GammaUnavailable(GammaError):
    """Raised when the Gamma API is unreachable after all retries."""


def _iso_z(dt: datetime) -> str:
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class GammaClient:
    """Thin, typed, retried wrapper around the Polymarket Gamma API."""

    COMMENTS_PAGE_SIZE = 500
    EVENTS_PAGE_LIMIT = 500

    def __init__(self, base_url: str, timeout: float, max_retries: int) -> None:
        self._base_url = base_url.rstrip("/")
        self._timeout = timeout
        self._max_retries = max_retries
        self._session = self._build_session(max_retries)

    @staticmethod
    def _build_session(max_retries: int) -> requests.Session:
        session = requests.Session()
        retry = Retry(
            total=max_retries,
            backoff_factor=1.0,
            status_forcelist=(429, 500, 502, 503, 504),
            allowed_methods=frozenset(["GET"]),
            respect_retry_after_header=True,
            raise_on_status=False,
        )
        adapter = HTTPAdapter(max_retries=retry)
        session.mount("http://", adapter)
        session.mount("https://", adapter)
        return session

    def _request(self, path: str, params: Any = None) -> Any:
        url = f"{self._base_url}{path}"

        @retry(
            reraise=True,
            retry=retry_if_exception_type((requests.RequestException, GammaUnavailable)),
            wait=wait_random_exponential(multiplier=1, max=30),
            stop=stop_after_attempt(self._max_retries),
        )
        def _do() -> Any:
            try:
                resp = self._session.get(url, params=params, timeout=self._timeout)
            except requests.RequestException as e:
                log.warning("gamma_request_error", extra={"path": path, "error": str(e)})
                raise
            if resp.status_code >= 500 or resp.status_code == 429:
                raise GammaUnavailable(
                    f"Gamma {path} returned {resp.status_code}: {resp.text[:200]}"
                )
            if resp.status_code >= 400:
                raise GammaError(
                    f"Gamma {path} returned {resp.status_code}: {resp.text[:200]}"
                )
            return resp.json()

        return _do()

    def public_search(self, term: str, limit_per_type: int = 50) -> PublicSearchResponse:
        data = self._request(
            "/public-search", params={"q": term, "limit_per_type": limit_per_type}
        )
        return PublicSearchResponse.model_validate(data)

    def get_events(
        self,
        *,
        ids: list[str] | None = None,
        start_date_min: datetime | None = None,
        end_date_max: datetime | None = None,
        limit: int = EVENTS_PAGE_LIMIT,
    ) -> list[PolymarketEvent]:
        params: list[tuple[str, Any]] = [("limit", limit)]
        if ids:
            for i in ids:
                params.append(("id", i))
        if start_date_min is not None:
            params.append(("start_date_min", _iso_z(start_date_min)))
        if end_date_max is not None:
            params.append(("end_date_max", _iso_z(end_date_max)))

        data = self._request("/events", params=params)
        if isinstance(data, dict) and "events" in data:
            data = data["events"]
        if not isinstance(data, list):
            return []
        return [PolymarketEvent.model_validate(item) for item in data]

    def get_comments(
        self,
        *,
        parent_entity_type: str,
        parent_entity_id: str,
        limit: int = COMMENTS_PAGE_SIZE,
        offset: int = 0,
        order: str = "createdAt",
        ascending: bool = False,
    ) -> list[PolymarketComment]:
        data = self._request(
            "/comments",
            params={
                "parent_entity_type": parent_entity_type,
                "parent_entity_id": parent_entity_id,
                "limit": limit,
                "offset": offset,
                "order": order,
                "ascending": "true" if ascending else "false",
            },
        )
        if not isinstance(data, list):
            return []
        return [PolymarketComment.model_validate(item) for item in data]

    def iter_event_comments(
        self,
        event_id: str,
        window_start: datetime,
        window_end: datetime,
    ) -> Iterator[PolymarketComment]:
        """Yield comments for `event_id` whose createdAt falls in [start, end).

        Pages newest-first; stops paging once a comment older than `window_start`
        is encountered (the API returns ordered results, so nothing older follows).
        """
        offset = 0
        page = self.COMMENTS_PAGE_SIZE
        while True:
            batch = self.get_comments(
                parent_entity_type="Event",
                parent_entity_id=event_id,
                limit=page,
                offset=offset,
            )
            if not batch:
                return
            stop = False
            for comment in batch:
                created = comment.created_at
                if created.tzinfo is None:
                    created = created.replace(tzinfo=timezone.utc)
                if created < window_start:
                    stop = True
                    break
                if created < window_end:
                    yield comment
            if stop or len(batch) < page:
                return
            offset += page
