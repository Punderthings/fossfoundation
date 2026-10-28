import json
from datetime import date
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

import pytest

from fdncrosswalk import cli, export, probes
from fdncrosswalk.crosswalk import (
    Account,
    Assessment,
    Evidence,
    Package,
    Person,
    assess,
    confidence,
    from_dict,
    load,
    load_attestors,
    load_dir,
    validate,
)
from fdncrosswalk.ecosystems import lookup_urls, package_lookup_urls

FIXTURES = Path(__file__).parent / "fixtures"
REPO_ROOT = Path(__file__).resolve().parents[4]
CROSSWALK_DIR = REPO_ROOT / "_data" / "crosswalk"
SCHEMA = json.loads((REPO_ROOT / "_data" / "crosswalk-schema.json").read_text(encoding="utf-8"))
TODAY = "2026-10-28"
MAILTO = "polite@example.org"


def account(*types: str, platform: str = "github.com", name: str = "apache", **extra) -> Account:
    evidence = tuple(Evidence(t, "https://example.org/", TODAY) for t in types)
    return Account(platform, "organization", name, f"https://example.org/{name}", evidence, **extra)


def fixture_fetch(mapping: dict[str, str]):
    def fetch(url: str, headers: dict[str, str]):
        return json.loads((FIXTURES / mapping[url]).read_text(encoding="utf-8"))

    return fetch


# --- confidence -------------------------------------------------------------


@pytest.mark.parametrize(
    ("types", "expected"),
    [
        (("steward-declared",), "confirmed"),
        (("platform-verified", "name-match"), "confirmed"),
        (("profile-claim",), "probable"),
        (("publish-provenance", "program-badge"), "probable"),
        (("name-match",), "unconfirmed"),
        (("steward-declared", "contradiction"), "rejected"),
    ],
)
def test_confidence(types, expected):
    assert confidence(account(*types)) == expected


# --- shipped data -----------------------------------------------------------


def test_every_shipped_crosswalk_is_valid():
    crosswalks = load_dir(CROSSWALK_DIR, SCHEMA)
    assert {cw.identifier for cw in crosswalks} >= {"asf", "eclipse", "numfocus", "openjsf", "python"}
    for cw in crosswalks:
        assert (REPO_ROOT / "_foundations" / f"{cw.identifier}.md").exists()


def test_psf_npm_lookalike_is_rejected():
    python = load(CROSSWALK_DIR / "python.json", SCHEMA)
    psf_npm = next(a for a in python.accounts if a.platform == "npmjs.org" and a.name == "@psf")
    assert confidence(psf_npm) == "rejected"


def test_schema_rejects_unknown_evidence_type_and_missing_evidence():
    bad = {
        "identifier": "x",
        "accounts": [
            {"platform": "github.com", "kind": "organization", "name": "x", "url": "https://github.com/x", "evidence": []},
            {
                "platform": "github.com",
                "kind": "organization",
                "name": "y",
                "url": "https://github.com/y",
                "evidence": [{"type": "vibes", "source": "https://example.org/", "observed": TODAY}],
            },
        ],
    }
    errors = validate(bad, SCHEMA)
    assert any(e.startswith("accounts/0/evidence") for e in errors)
    assert any(e.startswith("accounts/1/evidence/0/type") for e in errors)


def test_load_rejects_identifier_that_does_not_match_file(tmp_path):
    path = tmp_path / "asf.json"
    path.write_text(json.dumps({"identifier": "eclipse", "accounts": []}), encoding="utf-8")
    with pytest.raises(ValueError, match="does not match file name"):
        load(path, SCHEMA)


# --- ecosyste.ms lookups ----------------------------------------------------


def test_every_lookup_url_carries_mailto():
    for cw in load_dir(CROSSWALK_DIR, SCHEMA):
        for acct in cw.accounts:
            for url in lookup_urls(acct, MAILTO).values():
                assert parse_qs(urlsplit(url).query)["mailto"] == [MAILTO]


def test_github_lookup_includes_repos_and_sponsors():
    urls = lookup_urls(account("steward-declared"), MAILTO)
    assert urls["repos"].startswith("https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/apache?")
    assert urls["sponsors"].startswith("https://sponsors.ecosyste.ms/api/v1/accounts/apache?")


def test_self_hosted_forge_uses_instance_hostname():
    acct = account("steward-declared", platform="gitlab.com", name="eclipse", host="https://gitlab.eclipse.org")
    assert lookup_urls(acct, MAILTO) == {
        "repos": f"https://repos.ecosyste.ms/api/v1/hosts/gitlab.eclipse.org/owners/eclipse?mailto={MAILTO.replace('@', '%40')}"
    }


def test_npm_scope_is_url_encoded_and_pypi_org_has_no_lookup():
    npm = account("profile-claim", platform="npmjs.org", name="@openjs")
    assert "/registries/npmjs.org/namespaces/%40openjs?" in lookup_urls(npm, MAILTO)["packages"]
    assert lookup_urls(account("profile-claim", platform="pypi.org", name="psf")) == {}


# --- probes -----------------------------------------------------------------


def test_docker_hub_probe_reports_profile_and_badge():
    fetch = fixture_fetch({"https://hub.docker.com/v2/orgs/apache/": "docker-apache.json"})
    found = probes.docker_hub_org("apache", fetch, TODAY)
    assert [e.type for e in found] == ["profile-claim", "program-badge"]
    assert "The Apache Software Foundation" in found[0].detail
    assert found[0].observed == TODAY


def test_docker_hub_probe_without_badge():
    fetch = fixture_fetch({"https://hub.docker.com/v2/orgs/numfocus/": "docker-numfocus.json"})
    assert [e.type for e in probes.docker_hub_org("numfocus", fetch, TODAY)] == ["profile-claim"]


def test_pypi_provenance_probe_names_publisher_repository():
    fetch = fixture_fetch(
        {
            "https://pypi.org/simple/pyperf/": "pypi-simple-pyperf.json",
            "https://pypi.org/integrity/pyperf/2.10.0/pyperf-2.10.0.tar.gz/provenance": "pypi-provenance-pyperf.json",
        }
    )
    found = probes.pypi_provenance("pyperf", fetch, TODAY)
    assert len(found) == 1
    assert found[0].type == "publish-provenance"
    assert "psf/pyperf" in found[0].detail


def test_pypi_provenance_probe_without_attestations():
    fetch = lambda url, headers: {"files": [{"filename": "x-1.0.tar.gz", "provenance": None}]}  # noqa: E731
    assert probes.pypi_provenance("x", fetch, TODAY) == []


def test_npm_org_probe():
    assert "@psf/bch-js" in probes.npm_org_packages(
        "@psf", fixture_fetch({"https://registry.npmjs.org/-/org/psf/package": "npm-org-psf.json"})
    )
    missing = fixture_fetch({"https://registry.npmjs.org/-/org/nope/package": "npm-org-missing.json"})
    assert probes.npm_org_packages("nope", missing) == []


# --- command line -----------------------------------------------------------


def test_cli_report_and_urls(capsys):
    assert cli.main(["report"]) == 0
    report = capsys.readouterr().out
    assert "python\trejected\tnpmjs.org\tnamespace\t@psf" in report
    assert cli.main(["urls"]) == 0
    urls = capsys.readouterr().out
    assert "@psf" not in urls
    assert "repos.ecosyste.ms" in urls


def test_from_dict_keeps_optional_fields():
    cw = from_dict(
        {
            "identifier": "numfocus",
            "accounts": [
                {
                    "platform": "pypi.org",
                    "kind": "organization",
                    "name": "numpy",
                    "url": "https://pypi.org/org/numpy/",
                    "project": "numpy",
                    "evidence": [{"type": "profile-claim", "source": "https://pypi.org/org/numpy/", "observed": TODAY}],
                }
            ],
        }
    )
    assert cw.accounts[0].project == "numpy"
    assert cw.accounts[0].host is None


# --- human attestation and staleness ----------------------------------------

ATTESTORS = frozenset({"ShaneCurcuru"})
PERSON = {"email": "vp@example.org", "roleName": "VP Infrastructure"}


def attested(creator: str = "ShaneCurcuru", observed: str = TODAY, **extra) -> Evidence:
    return Evidence(
        "human-attested",
        "https://github.com/Punderthings/fossfoundation/pull/1",
        observed,
        creator=creator,
        method="video-call",
        confirmedWith=Person(**PERSON),
        **extra,
    )


def with_evidence(*items: Evidence) -> Account:
    return Account("github.com", "organization", "apache", "https://github.com/apache", items)


def test_human_attestation_confirms_only_for_listed_attestors():
    assert confidence(with_evidence(attested()), ATTESTORS) == "confirmed"
    assert confidence(with_evidence(attested("someone-else")), ATTESTORS) == "probable"
    assert confidence(with_evidence(attested()), frozenset()) == "probable"


def test_supersedes_overrides_older_contradiction_only():
    contradiction = Evidence("contradiction", "https://example.org/", "2026-01-01")
    later = attested(supersedes=True)
    assert confidence(with_evidence(contradiction, later), ATTESTORS) == "confirmed"
    assert confidence(with_evidence(contradiction, attested()), ATTESTORS) == "rejected"
    assert confidence(with_evidence(contradiction, attested("someone-else", supersedes=True)), ATTESTORS) == "rejected"
    earlier = attested(observed="2025-12-01", supersedes=True)
    assert confidence(with_evidence(contradiction, earlier), ATTESTORS) == "rejected"


@pytest.mark.parametrize(
    ("item", "today", "stale"),
    [
        (Evidence("platform-verified", "https://example.org/", TODAY), "2027-01-26", False),
        (Evidence("platform-verified", "https://example.org/", TODAY), "2027-01-27", True),
        (Evidence("steward-declared", "https://example.org/", TODAY), "2027-10-28", False),
        (Evidence("steward-declared", "https://example.org/", TODAY), "2027-10-29", True),
        (Evidence("profile-claim", "https://example.org/", TODAY, validThrough="2030-01-01"), "2029-12-31", False),
    ],
)
def test_staleness_windows(item, today, stale):
    result = assess(with_evidence(item), ATTESTORS, date.fromisoformat(today))
    assert result.stale is stale


def test_fresh_weaker_evidence_does_not_hide_stale_level():
    old = Evidence("platform-verified", "https://example.org/", "2025-01-01")
    fresh = Evidence("profile-claim", "https://example.org/", TODAY)
    assert assess(with_evidence(old, fresh), ATTESTORS, date(2026, 10, 28)) == Assessment("confirmed", stale=True)


def test_schema_requires_person_for_human_attested_and_forbids_it_elsewhere():
    base = {"source": "https://example.org/", "observed": TODAY}
    doc = lambda ev: {  # noqa: E731
        "identifier": "x",
        "accounts": [{"platform": "github.com", "kind": "organization", "name": "x", "url": "https://github.com/x", "evidence": [ev]}],
    }
    assert validate(doc({"type": "human-attested", **base}), SCHEMA)
    good = {"type": "human-attested", **base, "creator": "ShaneCurcuru", "method": "in-person", "confirmedWith": PERSON}
    assert validate(doc(good), SCHEMA) == []
    assert validate(doc({**good, "confirmedWith": {"roleName": "VP"}}), SCHEMA)
    assert validate(doc({"type": "profile-claim", **base, "method": "in-person"}), SCHEMA)


def test_shipped_attestors_file_is_valid():
    schema = json.loads((REPO_ROOT / "_data" / "attestors-schema.json").read_text(encoding="utf-8"))
    assert "ShaneCurcuru" in load_attestors(REPO_ROOT / "_data" / "attestors.json", schema)


# --- packages ---------------------------------------------------------------


def test_package_lookups_use_purl_and_papers():
    pypi = Package("pkg:pypi/numpy", (Evidence("repository-link", "https://example.org/", TODAY),))
    urls = package_lookup_urls(pypi, MAILTO)
    assert urls["packages"].startswith("https://packages.ecosyste.ms/api/v1/packages/lookup?purl=pkg%3Apypi%2Fnumpy&")
    assert urls["papers"].startswith("https://papers.ecosyste.ms/api/v1/projects/pypi/numpy?")
    repo = Package("pkg:github/apache/kafka", pypi.evidence)
    assert list(package_lookup_urls(repo, MAILTO)) == ["repos"]
    for url in [*urls.values(), *package_lookup_urls(repo, MAILTO).values()]:
        assert parse_qs(urlsplit(url).query)["mailto"] == [MAILTO]


def test_schema_rejects_versioned_package_purl():
    doc = {
        "identifier": "x",
        "accounts": [],
        "packages": [{"purl": "pkg:pypi/numpy@2.5.4", "evidence": [{"type": "name-match", "source": "https://example.org/", "observed": TODAY}]}],
    }
    assert any(e.startswith("packages/0/purl") for e in validate(doc, SCHEMA))


# --- exports ----------------------------------------------------------------


def test_foundation_document_and_steward_rows():
    numfocus = load(CROSSWALK_DIR / "numfocus.json", SCHEMA)
    info = export.foundation_info(REPO_ROOT / "_foundations", "numfocus")
    assert info["wikidataId"] == "Q54449592"
    doc = export.foundation_document(numfocus, info, ATTESTORS, date(2026, 10, 28))
    assert doc["@context"] == export.CONTEXT_URL
    assert doc["license"] == export.LICENSE
    github = next(a for a in doc["accounts"] if a["platform"] == "github.com" and a["name"] == "matplotlib")
    assert github["confidence"] == "confirmed"
    assert github["sameAs"] == "https://repos.ecosyste.ms/hosts/GitHub/owners/matplotlib"
    rows = export.steward_rows(numfocus, info, ATTESTORS, date(2026, 10, 28))
    assert any(r.get("host") == "GitHub" and r["login"] == "matplotlib" and r["uuid"] == "215947" for r in rows)
    assert any(r.get("purl") == "pkg:pypi/numpy" and r["registry"] == "pypi.org" for r in rows)
    assert not any(r.get("login") == "numfocus" for r in rows)  # unconfirmed links are not exported


def test_rejected_links_never_reach_stewards_feed():
    python = load(CROSSWALK_DIR / "python.json", SCHEMA)
    rows = export.steward_rows(python, {}, ATTESTORS, date(2026, 10, 28))
    assert not any(r.get("namespace") == "@psf" for r in rows)


def test_shipped_context_and_vocabulary_match_code():
    out = REPO_ROOT / export.EXPORT_PATH
    assert json.loads((out / "context.jsonld").read_text(encoding="utf-8")) == export.context()
    assert json.loads((out / "vocab.jsonld").read_text(encoding="utf-8")) == export.vocabulary()


def test_every_context_term_has_a_documented_mapping():
    terms = export.context()["@context"]
    for key in SCHEMA["definitions"]["evidence"]["properties"]:
        assert key in terms
    for key in SCHEMA["definitions"]["package"]["properties"]:
        assert key in terms
    fdn_terms = {t["@id"].removeprefix("fdn:") for t in export.vocabulary()["@graph"]}
    used = {(v if isinstance(v, str) else v["@id"]).removeprefix("fdn:") for v in terms.values() if "fdn:" in str(v)}
    assert used - {export.VOCAB} <= fdn_terms


def test_write_exports(tmp_path):
    crosswalks = load_dir(CROSSWALK_DIR, SCHEMA)
    written = export.write_exports(crosswalks, tmp_path, REPO_ROOT / "_foundations", ATTESTORS, date(2026, 10, 28))
    assert {p.name for p in written} >= {"context.jsonld", "vocab.jsonld", "stewards.jsonl", "asf.json"}
    lines = (tmp_path / "stewards.jsonl").read_text(encoding="utf-8").splitlines()
    assert all(json.loads(line)["confidence"] in {"confirmed", "probable"} for line in lines)


def test_sync_csv_adds_columns_and_keeps_existing_values():
    text = 'identifier,commonName,description\nkafka,Apache Kafka,"multi\nline"\nzookeeper,ZooKeeper,x\n'
    out = export.sync_csv(text, {"kafka": {"purl": "pkg:maven/org.apache.kafka/kafka-clients"}})
    assert out.splitlines()[0] == "identifier,commonName,description,purl,codeRepository"
    assert 'kafka,Apache Kafka,"multi\nline",pkg:maven/org.apache.kafka/kafka-clients,\n' in out
    assert export.sync_csv(out, {}) == out


def test_shipped_project_csvs_are_in_sync():
    for cw in load_dir(CROSSWALK_DIR, SCHEMA):
        path = REPO_ROOT / "_data" / f"projects-{cw.identifier}.csv"
        columns = export.project_columns(cw, ATTESTORS)
        if path.exists() and columns:
            text = path.read_text(encoding="utf-8")
            assert export.sync_csv(text, columns) == text


def test_lookup_urls_omit_mailto_when_not_configured():
    urls = lookup_urls(account("steward-declared"), "")
    assert urls["repos"] == "https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/apache"
    pypi = Package("pkg:pypi/numpy", (Evidence("repository-link", "https://example.org/", TODAY),))
    assert "mailto" not in package_lookup_urls(pypi, "")["packages"]
