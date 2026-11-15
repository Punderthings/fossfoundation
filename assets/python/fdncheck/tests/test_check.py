# SPDX-License-Identifier: Apache-2.0
"""End to end for one synthetic foundation: fetch (stubbed) -> detect -> propose, and the golden report."""

import json

from conftest import FIXTURES, DictFetcher
from scenario import PAGES

from fdncheck.check import known_ids, run_check
from fdncheck.propose import report
from fdncheck.records import foundation
from fdncheck.records.schema import load_catalog


def result(repo):
    record = foundation.load_id(repo, "acme")
    fetcher = DictFetcher(PAGES)
    return run_check(record, fetcher, load_catalog(repo), known_ids(repo)), fetcher


def summary(findings):
    return [(f.field, f.action, f.rule) for f in findings]


def test_each_url_is_fetched_once(repo):
    _result, fetcher = result(repo)
    assert len(fetcher.calls) == len(set(fetcher.calls)) == 9


def test_findings(repo):
    res, _ = result(repo)
    assert summary(res.findings) == [
        ("sponsorships", "flag", "unknown-reference"),
        ("website", "update", "redirect-permanent-same-site"),
        ("boardurl", "ok", "ok"),
        ("teamurl", "ok", "ok"),
        ("missionurl", "ok", "ok-equivalent-redirect"),
        ("donateurl", "flag", "redirect-temporary"),
        ("sponsorurl", "update", "redirect-permanent-same-site"),
        ("securityurl", "flag", "not-found"),
        ("conducturl", "unchecked", "blocked"),
        ("conductProjects", "update", "redirect-permanent-same-site"),
        ("conductProjects", "flag", "redirect-off-site"),
    ]


def test_proposed_text_changes_only_updated_lines(repo):
    res, _ = result(repo)
    before, after = res.record.text.splitlines(), res.proposed_text().splitlines()
    assert [(a, b) for a, b in zip(before, after, strict=True) if a != b] == [
        ("website: http://acme.example.org/", "website: https://acme.example.org/"),
        ("sponsorurl: https://acme.example.org/sponsors#list", "sponsorurl: https://acme.example.org/supporters#list"),
        ("- https://acme.example.org/old-coc", "- https://www.acme.example.org/code-of-conduct"),
    ]


def test_report_matches_golden_file(repo):
    res, _ = result(repo)
    assert report.markdown("acme", res.findings) == (FIXTURES / "acme-report.md").read_text(encoding="utf-8")


def test_commit_message_has_searchable_subject_and_trailers(repo):
    res, _ = result(repo)
    message = report.commit_message("acme", res.findings)
    lines = message.splitlines()
    assert lines[0] == "fdncheck(acme): update conductProjects, sponsorurl, website"
    assert lines[-3:] == ["Foundation: acme", "Checked-by: fdncheck/0.1.0", "Checked-on: 2026-11-15"]


def test_findings_json_carries_the_source_of_each_finding(repo):
    res, _ = result(repo)
    doc = json.loads(report.findings_json("acme", res.findings))
    website = next(f for f in doc["findings"] if f["field"] == "website")
    assert website["source"]["redirects"] == [[301, "https://acme.example.org/"]]
    assert website["source"]["fetched_at"] == "2026-11-15T12:00:00Z"
    assert doc["checkedOn"] == "2026-11-15"
