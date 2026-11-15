# SPDX-License-Identifier: Apache-2.0
"""Run every phase 1 check for one foundation: records -> fetch -> extract -> detect -> propose."""

from dataclasses import dataclass, field
from pathlib import Path

from fdncheck.detect import Finding
from fdncheck.detect.compare import check_joins, check_urls
from fdncheck.extract.links import page_observations
from fdncheck.fetch import Fetcher, Snapshot
from fdncheck.propose import frontmatter
from fdncheck.records.catalog import url_targets
from fdncheck.records.foundation import Record, ids_in


@dataclass
class CheckResult:
    record: Record
    findings: list[Finding]
    snapshots: dict[str, Snapshot] = field(default_factory=dict)

    @property
    def updates(self) -> list[Finding]:
        return [f for f in self.findings if f.action == "update"]

    def proposed_text(self) -> str:
        """The record with every update applied, changing only those lines."""
        changes = [(f.field, str(f.current), str(f.proposed)) for f in self.updates]
        return frontmatter.apply(self.record.text, changes)


def known_ids(root: Path) -> dict[str, frozenset[str]]:
    return {name: ids_in(root / name) for name in ("_entities", "_sponsorships", "_foundations")}


def run_check(record: Record, fetcher: Fetcher, known: dict[str, frozenset[str]]) -> CheckResult:
    snapshots: dict[str, Snapshot] = {}
    for _field, url in url_targets(record.data):
        if url not in snapshots:  # several fields often share a page; fetch it once
            snapshots[url] = fetcher.get(url)
    observations = {url: page_observations(snap) for url, snap in snapshots.items()}
    findings = check_joins(record.identifier, record.data, known, record.path.stem)
    findings += check_urls(record.identifier, record.data, snapshots, observations)
    return CheckResult(record, findings, snapshots)
