# SPDX-License-Identifier: Apache-2.0
import pytest
from conftest import FIXTURES, REPO_ROOT

from fdncheck.records import foundation
from fdncheck.records.catalog import KEYWORD, POLICY, Catalog
from fdncheck.records.schema import load_catalog, load_schema, validate

REAL = sorted((REPO_ROOT / "_foundations").glob("*.md"))


CATALOG = load_catalog(REPO_ROOT)


def test_every_schema_field_has_a_consistent_x_check():
    assert CATALOG.problems() == []
    assert set(CATALOG.fields) == set(load_schema(REPO_ROOT)["properties"])


def test_catalog_url_fields_are_the_schema_url_fields():
    schema = load_schema(REPO_ROOT)["properties"]
    urls = {k for k, v in schema.items() if v.get("format") == "url" or (v.get("items") or {}).get("format") == "url"}
    assert set(CATALOG.names("url")) == urls


def test_only_url_fields_may_be_updated():
    assert {s.name for s in CATALOG if s.may_update} == set(CATALOG.names("url"))


def test_reference_fields_join_local_folders():
    assert CATALOG["sponsorships"].joins == "_sponsorships"
    assert CATALOG["subOrganization"].joins == "_entities"
    assert CATALOG["identifier"].check == "reference"


def schema_of(**props):
    return {"properties": props}


def test_problems_report_missing_and_unknown_classes():
    catalog = Catalog(schema_of(a={"type": "string"}, b={KEYWORD: "guess", "type": "string"}))
    assert catalog.problems() == ["a: no x-check", "b: unknown x-check 'guess'"]
    assert list(catalog) == []


@pytest.mark.parametrize(
    ("prop", "message"),
    [
        ({KEYWORD: "text", "type": "string", "format": "url"}, "x: x-check 'text' but format 'url'"),
        ({KEYWORD: "url", "type": "string"}, "x: x-check 'url' but format 'none'"),
        ({KEYWORD: "fact", "type": "number"}, "x: x-check 'fact' but type 'number'"),
        ({KEYWORD: "count", "type": "string"}, "x: x-check 'count' but type 'string'"),
        ({KEYWORD: "text", "type": "string", "format": "date"}, "x: x-check 'text' but format 'date'"),
        (
            {KEYWORD: "text", "type": "string", "format": "jjresolver~entities~identifier~name~/e/"},
            "x: x-check 'text' but format 'jjresolver~entities~identifier~name~/e/' names another collection",
        ),
    ],
)
def test_problems_report_class_that_disagrees_with_type_or_format(prop, message):
    assert Catalog(schema_of(x=prop)).problems() == [message]


def test_policy_names_every_class_used_in_the_schema():
    assert {s.check for s in CATALOG} <= set(POLICY)


@pytest.mark.parametrize("path", REAL, ids=lambda p: p.stem)
def test_every_real_record_loads(path):
    record = foundation.load(path)
    assert record.identifier


def test_url_targets_expand_lists_and_skip_non_urls():
    record = foundation.load(FIXTURES / "acme-foundation.txt")
    targets = CATALOG.url_targets(record.data)
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
