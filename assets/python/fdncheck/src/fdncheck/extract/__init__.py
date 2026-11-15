# SPDX-License-Identifier: Apache-2.0
"""Extraction: pure functions from a Snapshot to Observations. Nothing here uses the network."""

from dataclasses import dataclass


@dataclass(frozen=True)
class Observation:
    """One value read from one page, with how it was found."""

    method: str  # e.g. "page:title", "page:needs-javascript"
    value: object
    source_url: str  # final URL of the Snapshot
    locator: str = ""  # CSS selector, JSON path or regex that matched
    excerpt: str = ""  # up to 200 characters of matched text, for the reviewer
