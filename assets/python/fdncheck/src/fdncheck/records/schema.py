# SPDX-License-Identifier: Apache-2.0
"""foundations-schema.json: loading, record validation, and catalog coverage."""

import json
from pathlib import Path

import jsonschema

from fdncheck.records.catalog import CATALOG
from fdncheck.records.foundation import Record, jsonable


def load_schema(root: Path) -> dict:
    return json.loads((root / "_data" / "foundations-schema.json").read_text(encoding="utf-8"))


def uncovered_fields(schema: dict) -> list[str]:
    """Schema properties the catalog doesn't describe; a test keeps this empty."""
    return [name for name in schema.get("properties", {}) if name not in CATALOG]


def validate(record: Record, schema: dict) -> list[str]:
    """Schema problems in one record, as readable strings.

    Blank values are left out first: the template lists every field, and an empty field
    means "unknown", not a wrong type. Formats are not checked, as on the site.
    """
    validator = jsonschema.Draft6Validator(schema)
    data = {k: v for k, v in jsonable(record.data).items() if v is not None and v != ""}
    return sorted(
        f"{'/'.join(str(p) for p in error.absolute_path) or '(record)'}: {error.message}"
        for error in validator.iter_errors(data)
    )
