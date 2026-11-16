# SPDX-License-Identifier: Apache-2.0
"""The JSON-LD context is built from the x-term of each crosswalk schema property; keep them consistent."""

import json
import re

import pytest

from fdncrosswalk import export

SCHEMA = json.loads(export.SCHEMA_PATH.read_text(encoding="utf-8"))
CROSSWALK_PAGE = export.SCHEMA_PATH.parents[1] / "_pages" / "crosswalk.md"
CURIE = re.compile(r"\b(?:schema|dcterms|prov|fdn):[A-Za-z]+")


def test_every_property_has_a_term():
    for holder in [SCHEMA, *SCHEMA["definitions"].values()]:
        for key, prop in holder.get("properties", {}).items():
            assert "x-term" in export._resolve(SCHEMA, prop), key


def test_terms_come_from_format_type_and_override():
    schema = {"properties": {
        "page": {"x-term": "schema:url", "type": "string", "format": "uri"},
        "seen": {"x-term": "prov:generatedAtTime", "type": "string", "format": "date"},
        "items": {"x-term": "fdn:item", "type": "array"},
        "where": {"x-term": "dcterms:source", "x-term-type": "@id", "type": "string"},
        "plain": {"x-term": "schema:name", "type": "string"},
        "skipped": {"type": "string"},
    }}
    context = export.context(schema)["@context"]
    expected = {
        "page": {"@id": "schema:url", "@type": "@id"},
        "seen": {"@id": "prov:generatedAtTime", "@type": "xsd:date"},
        "items": {"@id": "fdn:item", "@container": "@set"},
        "where": {"@id": "dcterms:source", "@type": "@id"},
        "plain": "schema:name",
    }
    assert {key: context[key] for key in expected} == expected
    assert "skipped" not in context


def test_same_key_with_different_terms_is_refused():
    schema = {"properties": {"name": {"x-term": "schema:name"}},
              "definitions": {"other": {"properties": {"name": {"x-term": "schema:alternateName"}}}}}
    with pytest.raises(ValueError, match="name"):
        export.schema_terms(schema)


def test_local_refs_take_the_term_of_their_target():
    schema = {"definitions": {"a": {"properties": {"when": {"x-term": "schema:dateCreated", "format": "date"}}},
                              "b": {"properties": {"when": {"$ref": "#/definitions/a/properties/when"}}}}}
    assert export.context(schema)["@context"]["when"] == {"@id": "schema:dateCreated", "@type": "xsd:date"}


@pytest.mark.parametrize(("heading", "definition"), [("## Accounts", "account"), ("## Packages", "package"),
                                                    ("## Evidence", "evidence")])
def test_crosswalk_page_names_the_schema_terms(heading, definition):
    """The Standard term column of each field table on the crosswalk page agrees with x-term."""
    text = CROSSWALK_PAGE.read_text(encoding="utf-8")
    section = text.split(heading, 1)[1].split("\n## ", 1)[0]
    props = SCHEMA["definitions"][definition]["properties"]
    checked = 0
    for row in section.splitlines():
        cells = row.split("|")
        if len(cells) < 4 or not cells[1].strip().startswith(("`", "<span")):
            continue
        fields = re.findall(r"`([A-Za-z]+)`", cells[1])
        terms = CURIE.findall(cells[2])
        for field, term in zip(fields, terms):
            assert export._resolve(SCHEMA, props[field])["x-term"] == term, field
            checked += 1
    assert checked
