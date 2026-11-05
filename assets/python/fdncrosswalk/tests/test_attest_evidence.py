# SPDX-License-Identifier: Apache-2.0
"""Tests for adding and renewing human-attested evidence (fdncrosswalk attest)."""

import json
import shutil
from datetime import date
from pathlib import Path

import pytest

from fdncrosswalk import attest, cli, export
from fdncrosswalk.crosswalk import PENDING_SOURCE, from_dict, validate

REPO_ROOT = Path(__file__).resolve().parents[4]
CROSSWALK_SCHEMA = json.loads((REPO_ROOT / "_data" / "crosswalk-schema.json").read_text(encoding="utf-8"))
ATTESTORS_SCHEMA = json.loads((REPO_ROOT / "_data" / "attestors-schema.json").read_text(encoding="utf-8"))
PEOPLE_SCHEMA = json.loads((REPO_ROOT / "_data" / "attestations-schema.json").read_text(encoding="utf-8"))
METHODS = attest.evidence_methods(CROSSWALK_SCHEMA)
TODAY = date(2026, 11, 4)
JANE = {"identifier": attest.TEST_IDENTIFIER, "roleName": "VP Of Testing", "memberOf": "asf", "email": "j@example.com"}


def scripted(answers):
    it = iter(answers)
    return lambda prompt: next(it)


def document():
    return {
        "identifier": "asf",
        "accounts": [
            {"platform": "github.com", "kind": "organization", "name": "apache", "url": "https://github.com/apache",
             "evidence": [{"type": "name-match", "source": "https://github.com/apache", "observed": "2026-10-28"}]},
            {"platform": "hub.docker.com", "kind": "organization", "name": "apache", "url": "https://hub.docker.com/u/apache",
             "evidence": [{"type": "contradiction", "source": "https://hub.docker.com/u/apache", "observed": "2026-10-28"}]},
        ],
        "packages": [{"purl": "pkg:pypi/example", "evidence": [
            {"type": "name-match", "source": "https://pypi.org/project/example/", "observed": "2026-10-28"}]}],
    }


def interview(answers, data=None, **kwargs):
    said, created = [], []

    def new_person():
        created.append(JANE)
        return JANE

    label, item = attest.evidence_interview(
        scripted(answers), said.append, data=data or document(), methods=METHODS, attestors={"ShaneCurcuru"},
        people={JANE["identifier"]: JANE}, new_person=new_person, today=TODAY, **kwargs,
    )
    return label, item, said, created


def test_targets_label_accounts_and_packages():
    assert list(attest.targets(document())) == ["github.com/apache", "hub.docker.com/apache", "pkg:pypi/example"]


def test_interview_with_known_person_builds_valid_evidence():
    # target 1, login, method 2 (video-call), date, identifier, detail, source default
    answers = ["1", "ShaneCurcuru", "2", "", attest.TEST_IDENTIFIER, "Confirmed on a call.", ""]
    label, item, _, created = interview(answers)
    assert label == "github.com/apache"
    assert item == {
        "type": "human-attested", "source": PENDING_SOURCE, "observed": "2026-11-04", "detail": "Confirmed on a call.",
        "creator": "ShaneCurcuru", "method": "video-call",
        "confirmedWith": {"identifier": attest.TEST_IDENTIFIER, "roleName": "VP Of Testing", "memberOf": "asf"},
    }
    assert not created
    data = document()
    attest.targets(data)[label]["evidence"].append(item)
    assert validate(data, CROSSWALK_SCHEMA) == []


def test_interview_creates_person_when_identifier_left_empty():
    _, item, _, created = interview(["", "3", "2026-11-01", "", "Confirmed by email.", "https://example.org/pr/1"],
                                    target="pkg:pypi/example", creator="someone")
    assert created == [JANE]
    assert "email" not in item["confirmedWith"]
    assert item["source"] == "https://example.org/pr/1"


def test_interview_asks_role_for_unknown_record_and_warns_non_attestor():
    other = "urn:uuid:12345678-1234-4123-8123-123456789abc"
    answers = ["someone", "1", "", "not-a-uuid", other, "Board member", "", "Confirmed.", ""]
    _, item, said, _ = interview(answers, target="github.com/apache")
    assert item["confirmedWith"] == {"identifier": other, "roleName": "Board member", "memberOf": "asf"}
    assert any("probable" in s for s in said)
    assert any("urn:uuid" in s for s in said)


def test_interview_offers_supersedes_for_contradicted_link():
    answers = ["ShaneCurcuru", "1", "", attest.TEST_IDENTIFIER, "The org moved back to the ASF.", "", "y"]
    _, item, _, _ = interview(answers, target="hub.docker.com/apache")
    assert item["supersedes"] is True


def test_unknown_target_is_refused():
    with pytest.raises(ValueError, match="no account or package"):
        interview([], target="github.com/nope")


def attested(observed, creator="ShaneCurcuru", **extra):
    return attest.evidence_item(creator=creator, method="in-person", confirmed_with=attest.confirmed_with(JANE),
                                observed=observed, detail="Confirmed.", source="https://example.org/pr/1") | extra


def with_evidence(*items):
    data = document()
    data["accounts"][0]["evidence"].extend(items)
    return data


def test_due_lists_stale_and_soon_stale_items_for_one_attestor():
    data = with_evidence(attested("2025-10-01"), attested("2025-12-15"), attested("2026-06-01"),
                         attested("2025-10-01", creator="someone"))
    found = attest.due([data], TODAY, "ShaneCurcuru")
    assert [(d.evidence["observed"], d.stale) for d in found] == [("2025-10-01", True), ("2025-12-15", False)]
    assert len(attest.due([data], TODAY)) == 3


def test_due_respects_valid_through():
    data = with_evidence(attested("2026-10-01", validThrough="2026-11-01"))
    assert attest.due([data], TODAY)[0].stale


def test_renew_updates_confirmed_items_only():
    first, second = attested("2025-10-01", validThrough="2026-10-01"), attested("2025-10-02")
    data = with_evidence(first, second)
    items = attest.due([data], TODAY)
    renewed = attest.renew(scripted(["y", "", "", "n"]), lambda s: None, items, methods=METHODS, today=TODAY)
    assert [d.evidence for d in renewed] == [first]
    assert first["observed"] == "2026-11-04" and first["source"] == PENDING_SOURCE and "validThrough" not in first
    assert first["method"] == "in-person"
    assert second["observed"] == "2025-10-02"
    assert validate(data, CROSSWALK_SCHEMA) == []


def test_export_leaves_out_pending_source():
    data = with_evidence(attested("2026-11-01", source=PENDING_SOURCE))
    doc = export.foundation_document(from_dict(data), {}, frozenset({"ShaneCurcuru"}), TODAY)
    evidence = doc["accounts"][0]["evidence"][-1]
    assert "source" not in evidence and evidence["type"] == "human-attested"


def test_attestors_may_record_their_own_organization():
    roles = [{"memberOf": "asf", "roleName": "VP Infrastructure"}, {"memberOf": "python", "roleName": "Director"},
             {"memberOf": "https://example.org/"}]
    entry = {"login": "someone", "name": "Some One", "dateAdded": "2026-11-04", "memberOf": roles}
    assert validate({"attestors": [entry]}, ATTESTORS_SCHEMA) == []
    assert validate({"attestors": [{k: v for k, v in entry.items() if k != "memberOf"}]}, ATTESTORS_SCHEMA) == []
    assert validate({"attestors": [entry | {"memberOf": "asf"}]}, ATTESTORS_SCHEMA)
    assert validate({"attestors": [entry | {"memberOf": [{"roleName": "Director"}]}]}, ATTESTORS_SCHEMA)


def test_consent_method_self_is_allowed():
    assert "self" in attest.methods(PEOPLE_SCHEMA)


@pytest.fixture
def workdir(tmp_path):
    shutil.copytree(REPO_ROOT / "_data" / "crosswalk", tmp_path / "crosswalk")
    return tmp_path


def test_cli_attest_adds_evidence(workdir, monkeypatch, capsys):
    people = workdir / "attestations.json"
    people.write_text(json.dumps({"attestations": []}), encoding="utf-8")
    other = "urn:uuid:12345678-1234-4123-8123-123456789abc"
    monkeypatch.setattr("builtins.input", scripted(["2", "", other, "Infrastructure lead", "", "Confirmed.", "", "y"]))
    argv = ["--dir", str(workdir / "crosswalk"), "--today", "2026-11-04", "attest", "asf",
            "--target", "github.com/apache", "--creator", "ShaneCurcuru", "--no-export",
            "--public-file", str(people), "--private-file", str(workdir / "missing.json")]
    assert cli.main(argv) == 0
    saved = json.loads((workdir / "crosswalk" / "asf.json").read_text(encoding="utf-8"))
    item = attest.targets(saved)["github.com/apache"]["evidence"][-1]
    assert item["method"] == "video-call" and item["source"] == PENDING_SOURCE
    out = capsys.readouterr().out
    assert "updated" in out
    assert cli.main(["--dir", str(workdir / "crosswalk"), "--today", "2026-11-04", "report"]) == 0
    assert "source pending\tasf\tgithub.com/apache" in capsys.readouterr().out


def test_cli_renew_needs_creator(workdir, capsys):
    assert cli.main(["--dir", str(workdir / "crosswalk"), "attest", "--renew"]) == 1
    assert "--creator" in capsys.readouterr().err


def test_validate_rejects_unknown_attestor_organization(tmp_path, capsys):
    path = tmp_path / "attestors.json"
    good = {"memberOf": "https://example.org/", "roleName": "Director"}
    entry = {"login": "someone", "name": "Some One", "dateAdded": "2026-11-04",
             "memberOf": [good, {"memberOf": "not-a-foundation"}]}
    path.write_text(json.dumps({"attestors": [entry]}), encoding="utf-8")
    assert cli.main(["--attestors", str(path), "validate"]) == 1
    assert "not-a-foundation" in capsys.readouterr().err
    path.write_text(json.dumps({"attestors": [entry | {"memberOf": [good, {"memberOf": "asf"}]}]}), encoding="utf-8")
    assert cli.main(["--attestors", str(path), "validate"]) == 0
