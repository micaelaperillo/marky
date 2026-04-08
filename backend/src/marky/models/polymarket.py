"""Pydantic models for the Polymarket Gamma API responses we consume."""
from __future__ import annotations

import json
from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, field_validator


class _GammaModel(BaseModel):
    """Base config: accept camelCase aliases, ignore unknown fields."""
    model_config = ConfigDict(populate_by_name=True, extra="ignore")


class PolymarketTag(_GammaModel):
    id: str
    label: str | None = None
    slug: str | None = None


class PolymarketMarket(_GammaModel):
    id: str
    question: str | None = None
    description: str | None = None
    outcome_prices: list[float] = Field(default_factory=list, alias="outcomePrices")
    volume: float = 0.0
    active: bool = False
    closed: bool = False

    @field_validator("outcome_prices", mode="before")
    @classmethod
    def _parse_outcome_prices(cls, v: Any) -> list[float]:
        if v is None or v == "":
            return []
        if isinstance(v, list):
            try:
                return [float(x) for x in v]
            except (TypeError, ValueError):
                return []
        if isinstance(v, str):
            try:
                parsed = json.loads(v)
            except json.JSONDecodeError:
                return []
            if not isinstance(parsed, list):
                return []
            try:
                return [float(x) for x in parsed]
            except (TypeError, ValueError):
                return []
        return []

    @field_validator("volume", mode="before")
    @classmethod
    def _coerce_volume(cls, v: Any) -> float:
        if v is None or v == "":
            return 0.0
        try:
            return float(v)
        except (TypeError, ValueError):
            return 0.0


class PolymarketEvent(_GammaModel):
    id: str
    slug: str | None = None
    title: str | None = None
    description: str | None = None
    start_date: datetime | None = Field(default=None, alias="startDate")
    end_date: datetime | None = Field(default=None, alias="endDate")
    comments_enabled: bool = Field(default=False, alias="commentsEnabled")
    tags: list[PolymarketTag] = Field(default_factory=list)
    markets: list[PolymarketMarket] = Field(default_factory=list)


class PolymarketProfile(_GammaModel):
    user_id: str | None = Field(default=None, alias="userId")
    display_name: str | None = Field(default=None, alias="displayName")
    pseudonym: str | None = None


class PolymarketComment(_GammaModel):
    id: str
    body: str | None = None
    created_at: datetime = Field(alias="createdAt")
    parent_entity_type: str | None = Field(default=None, alias="parentEntityType")
    parent_entity_id: str | None = Field(default=None, alias="parentEntityId")
    # Polymarket has been observed using both `parentCommentID` and `parentCommentId`.
    parent_comment_id: str | None = Field(
        default=None,
        validation_alias="parentCommentID",
        serialization_alias="parentCommentId",
    )
    profile: PolymarketProfile | None = None
    reaction_count: int = Field(default=0, alias="reactionCount")
    report_count: int = Field(default=0, alias="reportCount")


class PublicSearchResponse(_GammaModel):
    events: list[PolymarketEvent] = Field(default_factory=list)
