# SPDX-License-Identifier: Apache-2.0
"""nonprofitStatus values: the schema's pattern matches its list of values, and every
foundation record uses only listed values."""

import re

from conftest import REPO_ROOT

from fdncheck.records.foundation import load
from fdncheck.records.schema import load_schema, validate


def nonprofit_types(schema: dict) -> list[str]:
    return [item["const"] for item in schema["definitions"]["nonprofitType"]["oneOf"]]


def test_values_are_unique_and_described():
    schema = load_schema(REPO_ROOT)
    values = nonprofit_types(schema)
    assert len(values) == len(set(values))
    for item in schema["definitions"]["nonprofitType"]["oneOf"]:
        assert item["description"].strip(), item["const"]


def test_property_points_at_the_values():
    prop = load_schema(REPO_ROOT)["properties"]["nonprofitStatus"]
    assert prop["x-values"] == "#/definitions/nonprofitType"


def test_pattern_lists_exactly_the_values():
    schema = load_schema(REPO_ROOT)
    alternatives = "|".join(nonprofit_types(schema))
    expected = f"^({alternatives})(; ({alternatives}))*$"
    assert schema["properties"]["nonprofitStatus"]["pattern"] == expected


def test_pattern_accepts_lists_and_rejects_free_text():
    pattern = re.compile(load_schema(REPO_ROOT)["properties"]["nonprofitStatus"]["pattern"])
    assert pattern.match("Nonprofit501c3")
    assert pattern.match("BEAISBL; Nonprofit501c6")
    assert not pattern.match("charitable")
    assert not pattern.match("Nonprofit501c3;Nonprofit501c6")
    assert not pattern.match("Nonprofit501c3 ")


def test_every_record_uses_listed_values():
    schema = load_schema(REPO_ROOT)
    problems = {}
    for path in sorted((REPO_ROOT / "_foundations").glob("*.md")):
        errors = [e for e in validate(load(path), schema) if e.startswith("nonprofitStatus")]
        if errors:
            problems[path.stem] = errors
    assert problems == {}
