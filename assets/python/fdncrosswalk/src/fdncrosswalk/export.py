"""Build the public crosswalk exports and the purl columns of the project CSVs.

Exports are identifiers and our own judgements only; ecosyste.ms data is linked, never copied.
"""

import csv
import io
import json
from dataclasses import asdict
from datetime import date
from pathlib import Path
from typing import Any, Final

from fdncrosswalk.crosswalk import PENDING_SOURCE, Account, Crosswalk, Package, assess
from fdncrosswalk.ecosystems import PURL_HOSTS, PURL_REGISTRIES, owner_host, page_url, purl_type

SITE: Final[str] = "https://fossfoundation.info"
EXPORT_PATH: Final[str] = "api/v2/crosswalk"
CONTEXT_URL: Final[str] = f"{SITE}/{EXPORT_PATH}/context.jsonld"
VOCAB: Final[str] = f"{SITE}/crosswalk#"
LICENSE: Final[str] = "https://creativecommons.org/publicdomain/zero/1.0/"
CRA_URL: Final[str] = "https://eur-lex.europa.eu/eli/reg/2024/2847/oj"
EXPORTED_LEVELS: Final[frozenset[str]] = frozenset({"confirmed", "probable"})
CSV_COLUMNS: Final[tuple[str, ...]] = ("purl", "codeRepository")


def _drop_empty(data: dict[str, Any]) -> dict[str, Any]:
    return {k: v for k, v in data.items() if v not in (None, "", (), [], False)}


def _evidence(item: Account | Package) -> list[dict[str, Any]]:
    out = []
    for e in item.evidence:
        data = _drop_empty(asdict(e))
        if data.get("source") == PENDING_SOURCE:
            del data["source"]  # not an IRI yet; leave it out of the linked data
        if "confirmedWith" in data:
            data["confirmedWith"] = _drop_empty(data["confirmedWith"])
        out.append(data)
    return out


def foundation_info(foundations_dir: Path, identifier: str) -> dict[str, str]:
    """Read the flat key: value front matter of _foundations/<identifier>.md."""
    path = foundations_dir / f"{identifier}.md"
    if not path.exists():
        return {}
    lines = path.read_text(encoding="utf-8").split("\n")
    info = {}
    for line in lines[1 : lines.index("---", 1)]:
        key, sep, value = line.partition(":")
        if sep and not key.startswith((" ", "-")) and value.strip():
            info[key] = value.strip().strip("'\"")
    return info


def _last_date(cw: Crosswalk) -> str:
    items = (*cw.accounts, *cw.packages)
    dates = [e.observed for i in items for e in i.evidence] + [i.lastReviewed for i in items if i.lastReviewed]
    return max(dates, default="")


def foundation_document(
    cw: Crosswalk, info: dict[str, str], attestors: frozenset[str], today: date
) -> dict[str, Any]:
    """One foundation's crosswalk as JSON-LD, with computed confidence and ecosyste.ms links."""
    accounts = []
    for a in cw.accounts:
        result = assess(a, attestors, today)
        data = _drop_empty({k: v for k, v in asdict(a).items() if k != "evidence"})
        data.update(_drop_empty({"confidence": result.confidence, "stale": result.stale, "sameAs": page_url(a)}))
        data["evidence"] = _evidence(a)
        accounts.append(data)
    packages = []
    for p in cw.packages:
        result = assess(p, attestors, today)
        data = _drop_empty({k: v for k, v in asdict(p).items() if k != "evidence"})
        data.update(_drop_empty({"confidence": result.confidence, "stale": result.stale}))
        data["evidence"] = _evidence(p)
        packages.append(data)
    return _drop_empty(
        {
            "@context": CONTEXT_URL,
            "@id": f"{SITE}/foundations/{cw.identifier}",
            "identifier": cw.identifier,
            "name": info.get("commonName"),
            "wikidataId": info.get("wikidataId"),
            "license": LICENSE,
            "dateModified": _last_date(cw),
            "accounts": accounts,
            "packages": packages,
        }
    )


def _account_keys(a: Account) -> dict[str, str | None]:
    host = owner_host(a)
    if host:
        return {"host": host, "login": a.name, "uuid": a.platformId}
    if a.kind == "namespace":
        return {"registry": a.platform, "namespace": a.name}
    return {"registry": a.platform, "login": a.name}


def _package_keys(p: Package) -> dict[str, str | None]:
    kind = purl_type(p.purl)
    if kind in PURL_HOSTS:
        return {"host": PURL_HOSTS[kind], "purl": p.purl, "codeRepository": p.codeRepository}
    return {"registry": PURL_REGISTRIES.get(kind), "purl": p.purl, "codeRepository": p.codeRepository}


def steward_rows(
    cw: Crosswalk, info: dict[str, str], attestors: frozenset[str], today: date
) -> list[dict[str, Any]]:
    """Flat rows for stewards.jsonl: confirmed or probable links, keyed the way ecosyste.ms names things."""
    steward = {"steward": cw.identifier, "stewardName": info.get("commonName"), "stewardWikidata": info.get("wikidataId")}
    rows = []
    for item, keys in [(a, _account_keys(a)) for a in cw.accounts] + [(p, _package_keys(p)) for p in cw.packages]:
        result = assess(item, attestors, today)
        if result.confidence not in EXPORTED_LEVELS:
            continue
        rows.append(
            _drop_empty(
                {
                    **keys,
                    **steward,
                    "project": item.project,
                    "confidence": result.confidence,
                    "stale": result.stale,
                    "lastReviewed": item.lastReviewed,
                }
            )
        )
    return rows


# The crosswalk schema names the vocabulary term of each of its keys (x-term); the context is built
# from it, plus the few keys that only the exports add. vocabulary() keeps its own wording, written
# for linked-data readers, and a test checks that it defines every fdn: term the context uses.
SCHEMA_PATH: Final[Path] = Path(__file__).resolve().parents[5] / "_data" / "crosswalk-schema.json"
DATE_TYPE: Final[dict[str, str]] = {"@type": "xsd:date"}
LINK_TYPE: Final[dict[str, str]] = {"@type": "@id"}
TERM_TYPES: Final[dict[str, str]] = {"uri": "@id", "date": "xsd:date"}  # schema format -> JSON-LD @type
# Keys that only the exports add, with their terms.
EXPORT_TERMS: Final[dict[str, Any]] = {
    "wikidataId": "fdn:wikidataId",
    "license": {"@id": "schema:license", **LINK_TYPE},
    "dateModified": {"@id": "schema:dateModified", **DATE_TYPE},
    "sameAs": {"@id": "schema:sameAs", **LINK_TYPE},
    "confidence": "fdn:confidence",
    "stale": "fdn:stale",
    "steward": "fdn:steward",
}
def _load_schema() -> dict[str, Any]:
    return json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))


def _resolve(schema: dict[str, Any], prop: dict[str, Any]) -> dict[str, Any]:
    """A property with a local $ref merged over the definition it points to."""
    ref = prop.get("$ref", "")
    if not ref.startswith("#/"):
        return prop
    target: Any = schema
    for part in ref.removeprefix("#/").split("/"):
        target = target[part]
    return {**_resolve(schema, target), **prop}


def schema_terms(schema: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Every key with an x-term, from the top level and each definition, as key -> resolved property.

    A key used in several places must map to the same term everywhere, because the context is flat.
    """
    found: dict[str, dict[str, Any]] = {}
    for holder in [schema, *schema.get("definitions", {}).values()]:
        for key, prop in holder.get("properties", {}).items():
            prop = _resolve(schema, prop)
            if "x-term" not in prop:
                continue
            if key in found and _term_entry(found[key]) != _term_entry(prop):
                raise ValueError(f"{key}: maps to different terms in different places")
            found.setdefault(key, prop)
    return found


def _term_entry(prop: dict[str, Any]) -> Any:
    entry: dict[str, Any] = {"@id": prop["x-term"]}
    term_type = prop.get("x-term-type") or TERM_TYPES.get(prop.get("format", ""))
    if term_type:
        entry["@type"] = term_type
    if prop.get("type") == "array":
        entry["@container"] = "@set"
    return entry["@id"] if len(entry) == 1 else entry


def context(schema: dict[str, Any] | None = None) -> dict[str, Any]:
    """JSON-LD context mapping crosswalk keys to Schema.org, Dublin Core, PROV-O and our own terms."""
    terms = {key: _term_entry(prop) for key, prop in schema_terms(schema or _load_schema()).items()}
    return {
        "@context": {
            "@version": 1.1,
            "schema": "https://schema.org/",
            "dcterms": "http://purl.org/dc/terms/",
            "prov": "http://www.w3.org/ns/prov#",
            "xsd": "http://www.w3.org/2001/XMLSchema#",
            "fdn": VOCAB,
            **terms,
            **EXPORT_TERMS,
        }
    }


def vocabulary() -> dict[str, Any]:
    """RDFS definitions for the fdn: terms that no existing vocabulary covers."""
    terms = {
        "steward": (
            "Steward",
            (
                "The foundation acts as steward for the account or package. Where the foundation has said so "
                "publicly, this is the open-source software steward role of EU Cyber Resilience Act "
                "(Regulation (EU) 2024/2847) Article 3(14)."
            ),
            {"rdfs:subPropertyOf": {"@id": "schema:publisher"}, "rdfs:seeAlso": {"@id": CRA_URL}},
        ),
        "account": ("Account", "An org, namespace or owner on a code host or package registry that the foundation or one of its projects controls.", {}),
        "package": ("Package", "A package or source repository, identified by a Package URL, that belongs to the foundation or one of its projects.", {"rdfs:seeAlso": {"@id": "https://github.com/package-url/purl-spec"}}),
        "platform": ("Platform", "Code host or package registry, named as ecosyste.ms names it.", {"rdfs:seeAlso": {"@id": "https://ecosyste.ms/"}}),
        "host": ("Self-hosted instance", "Base URL of a self-hosted forge such as https://gitlab.eclipse.org.", {}),
        "accountKind": ("Account kind", "organization, namespace or user.", {}),
        "project": ("Hosted project", "Identifier of a hosted project of the foundation.", {}),
        "publishedUnder": ("Published under", "The account a package is published under.", {}),
        "confidence": ("Confidence", "confirmed, probable, unconfirmed or rejected, computed from the evidence.", {}),
        "stale": ("Stale", "True when every evidence item supporting the confidence level is past its freshness date.", {}),
        "confirmedWith": ("Confirmed with", "The person at the organization who confirmed a human-attested link.", {"rdfs:range": {"@id": "schema:Person"}}),
        "supersedes": ("Supersedes", "A human attestation that overrides earlier contradiction evidence.", {}),
        "wikidataId": ("Wikidata id", "The foundation's Wikidata item.", {"rdfs:seeAlso": {"@id": "https://www.wikidata.org/"}}),
    }
    graph = [
        {"@id": f"fdn:{key}", "@type": "rdf:Property", "rdfs:label": label, "rdfs:comment": comment, **extra}
        for key, (label, comment, extra) in terms.items()
    ]
    return {
        "@context": {
            "fdn": VOCAB,
            "rdf": "http://www.w3.org/1999/02/22-rdf-syntax-ns#",
            "rdfs": "http://www.w3.org/2000/01/rdf-schema#",
            "schema": "https://schema.org/",
        },
        "@graph": graph,
    }


def write_exports(
    crosswalks: list[Crosswalk], out_dir: Path, foundations_dir: Path, attestors: frozenset[str], today: date
) -> list[Path]:
    """Write <identifier>.json, context.jsonld, vocab.jsonld and stewards.jsonl; return the paths written."""
    out_dir.mkdir(parents=True, exist_ok=True)
    written = []

    def dump(name: str, data: Any) -> None:
        path = out_dir / name
        path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        written.append(path)

    dump("context.jsonld", context())
    dump("vocab.jsonld", vocabulary())
    lines = []
    for cw in crosswalks:
        info = foundation_info(foundations_dir, cw.identifier)
        dump(f"{cw.identifier}.json", foundation_document(cw, info, attestors, today))
        lines += [json.dumps(row, ensure_ascii=False) for row in steward_rows(cw, info, attestors, today)]
    stewards = out_dir / "stewards.jsonl"
    stewards.write_text("".join(f"{line}\n" for line in lines), encoding="utf-8")
    written.append(stewards)
    return written


def project_columns(cw: Crosswalk, attestors: frozenset[str] = frozenset()) -> dict[str, dict[str, str]]:
    """Main purl and code repository per hosted project, from the first non-rejected packages listed."""
    columns: dict[str, dict[str, str]] = {}
    for p in cw.packages:
        if not p.project or assess(p, attestors).confidence == "rejected":
            continue
        row = columns.setdefault(p.project, {})
        row.setdefault("purl", p.purl)
        if p.codeRepository:
            row.setdefault("codeRepository", p.codeRepository)
    return columns


def sync_csv(text: str, columns: dict[str, dict[str, str]]) -> str:
    """Return a project CSV with purl and codeRepository columns filled from the crosswalk."""
    rows = list(csv.reader(io.StringIO(text, newline="")))
    header = rows[0]
    for name in CSV_COLUMNS:
        if name not in header:
            header.append(name)
            for row in rows[1:]:
                row.append("")
    key = header.index("identifier")
    for row in rows[1:]:
        values = columns.get(row[key], {})
        for name in CSV_COLUMNS:
            row[header.index(name)] = values.get(name, row[header.index(name)])
    out = io.StringIO()
    csv.writer(out, lineterminator="\n").writerows(rows)
    return out.getvalue()
