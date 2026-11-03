# SPDX-License-Identifier: Apache-2.0
import json
import re
from datetime import date
from pathlib import Path

import pytest

from fdncrosswalk import attest, cli
from fdncrosswalk.crosswalk import validate

REPO_ROOT = Path(__file__).resolve().parents[4]
SCHEMA = json.loads((REPO_ROOT / "_data" / "attestations-schema.json").read_text(encoding="utf-8"))
CROSSWALK_SCHEMA = json.loads((REPO_ROOT / "_data" / "crosswalk-schema.json").read_text(encoding="utf-8"))
TODAY = date(2026, 11, 3)

# Answers in question order for a private record; consent method 3 is email-official-domain.
PRIVATE = ["private", "Jane Doe", "jane@example.com", "VP Of Testing", "asf", "ShaneCurcuru", "3", "", "", "", "", ""]


def scripted(answers):
    it = iter(answers)
    return lambda prompt: next(it)


def run(answers, **kwargs):
    said = []
    record = attest.interview(
        scripted(answers),
        said.append,
        schema=SCHEMA,
        foundations={"asf", "python"},
        attestors={"ShaneCurcuru"},
        today=TODAY,
        **kwargs,
    )
    return record, said


def test_interview_builds_valid_private_record():
    record, _ = run(PRIVATE)
    assert re.fullmatch(r"urn:uuid:[0-9a-f-]{36}", record["identifier"])
    assert record["identifier"] != attest.TEST_IDENTIFIER
    assert record["visibility"] == "private"
    assert record["consent"] == {
        "dateGiven": "2026-11-03",
        "method": "email-official-domain",
        "purpose": attest.DEFAULT_PURPOSE,
        "legalBasis": attest.LEGAL_BASIS,
    }
    assert record["retainUntil"] == "2027-11-03"
    assert record["usedIn"] == [attest.CROSSWALK_URL.format("asf")]
    assert validate({"attestations": [record]}, SCHEMA) == []


def test_identifiers_are_random():
    assert run(PRIVATE)[0]["identifier"] != run(PRIVATE)[0]["identifier"]


def test_test_records_use_all_zeros():
    record, _ = run(PRIVATE, test=True)
    assert record["identifier"] == attest.TEST_IDENTIFIER
    assert record["testRecord"] is True


def test_public_needs_agreement_to_publish():
    record, _ = run(["public", "y", *PRIVATE[1:]])
    assert record["visibility"] == "public"
    assert record["consent"]["publish"] is True
    record, said = run(["public", "n", *PRIVATE[1:]])
    assert record["visibility"] == "private"
    assert "publish" not in record["consent"]
    assert any("private repository" in s for s in said)


def test_public_record_without_publish_consent_is_invalid():
    record, _ = run(["public", "y", *PRIVATE[1:]])
    del record["consent"]["publish"]
    assert validate({"attestations": [record]}, SCHEMA)


def test_bad_answers_are_asked_again():
    answers = ["private", "", "not-an-email", "jane@example.com", "VP", "nope", "asf", "someone", "9", "1",
               "03/11/2026", "", "", "", "", ""]
    record, said = run(answers)
    assert "name" not in record
    assert record["memberOf"] == "asf"
    assert record["consent"]["method"] == "in-person"
    assert any("not an email" in s for s in said)
    assert any("attestors.json" in s for s in said)


def test_confirmed_with_has_no_email_and_fits_crosswalk_schema():
    record, _ = run(PRIVATE)
    person = attest.confirmed_with(record)
    assert "email" not in person and "name" not in person
    evidence = {
        "type": "human-attested",
        "source": "https://github.com/Punderthings/fossfoundation/pull/1",
        "observed": "2026-11-03",
        "creator": "ShaneCurcuru",
        "method": "email-official-domain",
        "confirmedWith": person,
    }
    doc = {
        "identifier": "asf",
        "accounts": [
            {"platform": "github.com", "kind": "organization", "name": "apache", "url": "https://github.com/apache",
             "evidence": [evidence]}
        ],
    }
    assert validate(doc, CROSSWALK_SCHEMA) == []
    assert validate(doc | {"accounts": [doc["accounts"][0] | {"evidence": [evidence | {"confirmedWith": {"roleName": "VP"}}]}]}, CROSSWALK_SCHEMA)


def test_add_record_refuses_duplicates(tmp_path):
    path = tmp_path / "attestations.json"
    record, _ = run(PRIVATE)
    attest.add_record(path, record, SCHEMA)
    assert json.loads(path.read_text(encoding="utf-8"))["attestations"] == [record]
    with pytest.raises(ValueError, match="already"):
        attest.add_record(path, run(PRIVATE)[0], SCHEMA)


def test_cli_add_person_writes_private_file(tmp_path, monkeypatch):
    path = tmp_path / "private" / "attestations.json"
    path.parent.mkdir()
    said = []
    monkeypatch.setattr("builtins.input", scripted([*PRIVATE, "y"]))
    monkeypatch.setattr("builtins.print", said.append)
    assert cli.main(["--today", "2026-11-03", "add-person", "--private-file", str(path)]) == 0
    saved = json.loads(path.read_text(encoding="utf-8"))["attestations"]
    assert saved[0]["email"] == "jane@example.com"
    assert any('"identifier"' in s and "jane@" not in s for s in said)


def test_cli_refuses_private_file_inside_public_repo(monkeypatch, capsys):
    monkeypatch.setattr("builtins.input", scripted(PRIVATE))
    inside = REPO_ROOT / "_data" / "private-attestations.json"
    assert cli.main(["add-person", "--private-file", str(inside)]) == 1
    assert "inside the public repository" in capsys.readouterr().err
    assert not inside.exists()


def test_shipped_public_attestations_are_valid():
    assert cli.main(["validate"]) == 0
