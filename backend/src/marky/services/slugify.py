"""Topic → URL/key-safe slug helper."""
from __future__ import annotations

import re

_NON_ALNUM = re.compile(r"[^a-z0-9]+")


def slugify(text: str) -> str:
    """Lowercase, replace non-alphanumeric runs with `-`, strip edges.

    Non-ASCII characters (e.g. accented letters) are treated as non-alphanumeric.
    Returns an empty string when no alphanumeric characters survive.
    """
    lowered = text.strip().lower()
    collapsed = _NON_ALNUM.sub("-", lowered)
    return collapsed.strip("-")
