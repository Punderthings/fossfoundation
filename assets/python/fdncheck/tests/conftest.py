# SPDX-License-Identifier: Apache-2.0
"""Shared test helpers. No test uses the network.

fixtures/acme-foundation.txt is a made-up foundation record. It is stored as .txt so the
website build doesn't publish it as a page; tests copy it to _foundations/acme.md.
"""

import shutil
from pathlib import Path

import pytest

from fdncheck.fetch import Snapshot

REPO_ROOT = Path(__file__).resolve().parents[4]
FIXTURES = Path(__file__).parent / "fixtures"
WHEN = "2026-11-15T12:00:00Z"


def snap(url: str, status: int = 200, redirects=(), body: bytes = b"<html><title>x</title></html>", **kw):
    final = redirects[-1][1] if redirects else url
    return Snapshot(
        url,
        kw.pop("final_url", final),
        status,
        kw.pop("fetched_at", WHEN),
        tuple(redirects),
        kw.pop("content_type", "text/html"),
        body,
        **kw,
    )


class DictFetcher:
    """A Fetcher backed by a dict; unknown URLs fail like a dropped connection."""

    def __init__(self, pages: dict[str, Snapshot]):
        self.pages = pages
        self.calls: list[str] = []

    def get(self, url: str) -> Snapshot:
        self.calls.append(url)
        return self.pages.get(url) or Snapshot(url, url, 0, WHEN, error="ConnectError: unknown in test")


@pytest.fixture
def repo(tmp_path: Path) -> Path:
    """A tiny repository root: the real schema, one synthetic foundation, one entity, one sponsorship."""
    (tmp_path / "_data").mkdir()
    shutil.copy(REPO_ROOT / "_data" / "foundations-schema.json", tmp_path / "_data")
    for folder in ("_foundations", "_entities", "_sponsorships"):
        (tmp_path / folder).mkdir()
    shutil.copy(FIXTURES / "acme-foundation.txt", tmp_path / "_foundations" / "acme.md")
    (tmp_path / "_entities" / "acmeproject.md").write_text("---\nidentifier: acmeproject\n---\n", encoding="utf-8")
    (tmp_path / "_sponsorships" / "acme.md").write_text("---\nidentifier: acme\n---\n", encoding="utf-8")
    return tmp_path
