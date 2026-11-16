# SPDX-License-Identifier: Apache-2.0
"""The evidence types and their rules are read from _data/crosswalk-schema.json; keep them sound."""

import json

from fdncrosswalk.crosswalk import (
    CONFIDENCE_LEVELS,
    CONFIRMING,
    CONTRADICTING,
    EVIDENCE_TYPES,
    HUMAN_ATTESTED,
    SCHEMA_PATH,
    SUPPORTING,
    evidence_types,
)

SCHEMA = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))
ATTESTATIONS_SCHEMA = json.loads((SCHEMA_PATH.parent / "attestations-schema.json").read_text(encoding="utf-8"))


def test_rules_read_from_schema():
    assert CONFIRMING == {"steward-declared", "platform-verified"}
    assert SUPPORTING == {"profile-claim", "program-badge", "publish-provenance", "repository-link", "namespace-convention"}
    assert EVIDENCE_TYPES["name-match"].gives == "unconfirmed"


def test_every_type_gives_a_known_level_and_is_documented():
    for entry in SCHEMA["definitions"]["evidence"]["properties"]["type"]["oneOf"]:
        assert entry["x-gives"] in CONFIDENCE_LEVELS, entry["const"]
        assert entry["description"] and entry["x-asserted-by"], entry["const"]


def test_special_types_match_the_code():
    """The code treats human-attested and contradiction specially, so the schema must agree."""
    assert [t.name for t in EVIDENCE_TYPES.values() if t.attestor_only] == [HUMAN_ATTESTED]
    assert [t.name for t in EVIDENCE_TYPES.values() if t.gives == "rejected"] == [CONTRADICTING]
    assert [t.name for t in EVIDENCE_TYPES.values() if t.freshness_days is None] == [CONTRADICTING]


def test_freshness_windows():
    days = {t.name: t.freshness_days for t in EVIDENCE_TYPES.values() if t.freshness_days}
    assert {name for name, d in days.items() if d == 365} == {"steward-declared", HUMAN_ATTESTED}
    assert {d for name, d in days.items() if d != 365} == {90}


def test_evidence_types_reads_optional_keywords():
    schema = {"definitions": {"evidence": {"properties": {"type": {"oneOf": [
        {"const": "a", "x-gives": "probable", "x-freshness-days": 30},
        {"const": "b", "x-gives": "confirmed", "x-attestor-only": True},
    ]}}}}}
    types = evidence_types(schema)
    assert list(types) == ["a", "b"]
    assert (types["a"].freshness_days, types["a"].attestor_only) == (30, False)
    assert (types["b"].freshness_days, types["b"].attestor_only) == (None, True)


def test_consent_methods_are_the_evidence_methods_plus_self():
    evidence = SCHEMA["definitions"]["evidence"]["properties"]["method"]["enum"]
    consent = ATTESTATIONS_SCHEMA["definitions"]["attestation"]["properties"]["consent"]["properties"]["method"]["enum"]
    assert consent == [*evidence, "self"]
