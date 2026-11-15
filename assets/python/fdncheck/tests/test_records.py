# SPDX-License-Identifier: Apache-2.0
import pytest
from conftest import FIXTURES, REPO_ROOT

from fdncheck.records import foundation
from fdncheck.records.catalog import CATALOG, URL_FIELDS, url_targets
from fdncheck.records.schema import load_schema, uncovered_fields, validate

REAL = sorted((REPO_ROOT / "_foundations").glob("*.md"))


def test_catalog_covers_every_schema_field():
    assert uncovered_fields(load_schema(REPO_ROOT)) == []


def test_catalog_url_fields_are_the_schema_url_fields():
    schema = load_schema(REPO_ROOT)["properties"]
    urls = {k for k, v in schema.items() if v.get("format") == "url" or (v.get("items") or {}).get("format") == "url"}
    assert set(URL_FIELDS) == urls


def test_only_url_fields_may_be_updated():
    assert {s.name for s in CATALOG.values() if s.may_update} == set(URL_FIELDS)


@pytest.mark.parametrize("path", REAL, ids=lambda p: p.stem)
def test_every_real_record_loads(path):
    record = foundation.load(path)
    assert record.identifier


def test_url_targets_expand_lists_and_skip_non_urls():
    record = foundation.load(FIXTURES / "acme-foundation.txt")
    targets = url_targets(record.data)
    assert ("contacturl", "mailto:hello@example.org") not in targets
    assert ("conductProjects", "https://acme.example.org/old-coc") in targets
    assert ("conductProjects", "https://acme.example.org/project-coc") in targets
    assert targets[0] == ("website", "http://acme.example.org/")


def test_validate_allows_blank_values_and_reports_wrong_types():
    record = foundation.load(FIXTURES / "acme-foundation.txt")
    schema = load_schema(REPO_ROOT)
    assert validate(record, schema) == []
    bad = foundation.Record("acme", record.path, record.text, {**record.data, "boardSize": "five"})
    assert validate(bad, schema) == ["boardSize: 'five' is not of type 'number'"]


def test_records_without_front_matter_are_errors(tmp_path):
    path = tmp_path / "x.md"
    path.write_text("no front matter\n", encoding="utf-8")
    with pytest.raises(foundation.RecordError):
        foundation.load(path)
