# SPDX-License-Identifier: Apache-2.0
"""Observations about a page itself: its title, and whether it needs JavaScript to show content."""

from bs4 import BeautifulSoup

from fdncheck.extract import Observation
from fdncheck.fetch import Snapshot

MIN_VISIBLE_TEXT = 200  # characters of visible text below which a scripted page probably needs JavaScript


def is_html(snapshot: Snapshot) -> bool:
    kind = snapshot.content_type.split(";")[0].strip().lower()
    return kind in ("text/html", "application/xhtml+xml") or (not kind and snapshot.body.lstrip()[:1] == b"<")


def page_observations(snapshot: Snapshot) -> list[Observation]:
    """Title and a needs-JavaScript hint for an HTML page; nothing for other content."""
    if snapshot.error or not snapshot.body or not is_html(snapshot):
        return []
    soup = BeautifulSoup(snapshot.body, "html.parser")
    found: list[Observation] = []
    if soup.title and soup.title.string:
        title = " ".join(soup.title.string.split())
        found.append(Observation("page:title", title, snapshot.final_url, "title", title[:200]))
    has_script = soup.find("script") is not None
    for tag in soup(["script", "style", "noscript", "template"]):
        tag.decompose()
    body = soup.body or soup
    text = " ".join(body.get_text(" ").split())
    if has_script and len(text) < MIN_VISIBLE_TEXT:
        found.append(
            Observation(
                "page:needs-javascript",
                True,
                snapshot.final_url,
                "body text",
                f"{len(text)} characters of text without JavaScript",
            )
        )
    return found
