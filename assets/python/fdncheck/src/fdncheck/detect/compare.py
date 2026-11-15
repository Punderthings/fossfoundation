# SPDX-License-Identifier: Apache-2.0
"""Compare one record with its Snapshots and the other collections, producing Findings."""

from collections.abc import Mapping

from fdncheck.detect import Finding
from fdncheck.detect.policy import decide_url
from fdncheck.extract import Observation
from fdncheck.fetch import Snapshot
from fdncheck.records.catalog import CATALOG, url_targets


def _as_list(value: object) -> list:
    if value is None or value == "":
        return []
    return value if isinstance(value, list) else [value]


def check_joins(identifier: str, data: dict, known: Mapping[str, frozenset[str]], filename: str) -> list[Finding]:
    """Class G: the identifier matches the file name, and referenced ids exist in their collections."""
    findings: list[Finding] = []
    if data.get("identifier") != filename:
        findings.append(
            Finding(
                identifier,
                "identifier",
                data.get("identifier"),
                "flag",
                "identifier-filename",
                f"identifier does not match the file name {filename}.md",
            )
        )
    for spec in CATALOG.values():
        if not spec.joins or spec.joins not in known:
            continue
        for value in _as_list(data.get(spec.name)):
            if str(value) not in known[spec.joins]:
                findings.append(
                    Finding(identifier, spec.name, value, "flag", "unknown-reference", f"no {spec.joins}/{value}.md")
                )
    return findings


def check_urls(
    identifier: str,
    data: dict,
    snapshots: Mapping[str, Snapshot],
    observations: Mapping[str, list[Observation]],
) -> list[Finding]:
    """Class A: one Finding per (field, url), in catalog order."""
    findings: list[Finding] = []
    for field, url in url_targets(data):
        snapshot = snapshots[url]
        needs_js = any(o.method == "page:needs-javascript" for o in observations.get(url, []))
        findings.append(decide_url(identifier, field, url, snapshot, needs_js))
    return findings
