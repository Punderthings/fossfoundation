# SPDX-License-Identifier: Apache-2.0
"""Web scraping: fetch pages and return them as Snapshots.

This is the only package in fdncheck that uses the network. It knows nothing about
foundations or fields: it takes a URL and returns what the server sent, including every
redirect. HTTP errors are data in a Snapshot, never exceptions.
"""

import hashlib
from dataclasses import dataclass, field
from typing import Protocol


@dataclass(frozen=True)
class Snapshot:
    """One fetch of one URL, with everything a reviewer needs to check it again."""

    requested_url: str
    final_url: str
    status: int  # final HTTP status; 0 when no response was received
    fetched_at: str  # ISO 8601 UTC, e.g. 2026-11-15T18:00:00Z
    redirects: tuple[tuple[int, str], ...] = ()  # (status, Location) for each hop, in order
    content_type: str = ""
    body: bytes = b""
    rendered: bool = False  # True if JavaScript ran (phase 2)
    error: str | None = None  # e.g. "timeout", "robots-disallowed", "dns: ..."
    truncated: bool = field(default=False)

    @property
    def sha256(self) -> str:
        return hashlib.sha256(self.body).hexdigest()

    @property
    def checked_on(self) -> str:
        """The date part of fetched_at."""
        return self.fetched_at[:10]


class Fetcher(Protocol):
    """Anything that turns a URL into a Snapshot: a live HTTP fetcher or a saved store."""

    def get(self, url: str) -> Snapshot: ...
