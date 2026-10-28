"""Load, validate and score foundation crosswalk files (_data/crosswalk/*.json)."""

import json
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Final

import jsonschema

# Ordered strongest first; "rejected" means evidence shows someone else controls the account.
CONFIDENCE_LEVELS: Final[tuple[str, ...]] = ("confirmed", "probable", "unconfirmed", "rejected")

CONFIRMING: Final[frozenset[str]] = frozenset({"steward-declared", "platform-verified"})
SUPPORTING: Final[frozenset[str]] = frozenset(
    {
        "profile-claim",
        "program-badge",
        "publish-provenance",
        "repository-link",
        "namespace-convention",
    }
)
HUMAN_ATTESTED: Final[str] = "human-attested"
CONTRADICTING: Final[str] = "contradiction"

# How long evidence stays fresh when it has no validThrough date. Contradictions never expire.
LONG_LIVED: Final[frozenset[str]] = frozenset({"steward-declared", HUMAN_ATTESTED})
LONG_FRESHNESS: Final[timedelta] = timedelta(days=365)
SHORT_FRESHNESS: Final[timedelta] = timedelta(days=90)


@dataclass(frozen=True)
class Person:
    email: str
    roleName: str
    name: str | None = None
    memberOf: str | None = None


@dataclass(frozen=True)
class Evidence:
    type: str
    source: str
    observed: str
    detail: str = ""
    creator: str | None = None
    about: str | None = None
    method: str | None = None
    confirmedWith: Person | None = None
    validThrough: str | None = None
    supersedes: bool = False


@dataclass(frozen=True)
class Account:
    platform: str
    kind: str
    name: str
    url: str
    evidence: tuple[Evidence, ...]
    host: str | None = None
    project: str | None = None
    platformId: str | None = None
    lastReviewed: str | None = None
    reviewedBy: str | None = None


@dataclass(frozen=True)
class Package:
    purl: str
    evidence: tuple[Evidence, ...]
    codeRepository: str | None = None
    account: str | None = None
    project: str | None = None
    lastReviewed: str | None = None
    reviewedBy: str | None = None


@dataclass(frozen=True)
class Crosswalk:
    identifier: str
    accounts: tuple[Account, ...]
    packages: tuple[Package, ...] = ()


@dataclass(frozen=True)
class Assessment:
    """Computed confidence, plus whether every item supporting that level is past its freshness date."""

    confidence: str
    stale: bool = False


def _strength(item: Evidence, attestors: frozenset[str]) -> str:
    if item.type == CONTRADICTING:
        return "rejected"
    if item.type in CONFIRMING or (item.type == HUMAN_ATTESTED and item.creator in attestors):
        return "confirmed"
    if item.type in SUPPORTING or item.type == HUMAN_ATTESTED:
        return "probable"
    return "unconfirmed"


def expires(item: Evidence) -> date | None:
    """Date after which an evidence item is stale; None if it never expires."""
    if item.type == CONTRADICTING:
        return None
    if item.validThrough:
        return date.fromisoformat(item.validThrough)
    window = LONG_FRESHNESS if item.type in LONG_LIVED else SHORT_FRESHNESS
    return date.fromisoformat(item.observed) + window


def assess(
    item: Account | Package, attestors: frozenset[str] = frozenset(), today: date | None = None
) -> Assessment:
    """Derive confidence from evidence; with today, also report whether that level rests on stale evidence.

    Human-attested evidence confirms only when its creator is a listed attestor. A contradiction
    rejects unless a listed attestor's later human-attested item sets supersedes.
    """
    contradictions = [e for e in item.evidence if e.type == CONTRADICTING]
    if contradictions:
        latest = max(e.observed for e in contradictions)
        overridden = any(
            e.type == HUMAN_ATTESTED and e.supersedes and e.creator in attestors and e.observed > latest
            for e in item.evidence
        )
        if not overridden:
            return Assessment("rejected")
    rest = [e for e in item.evidence if e.type != CONTRADICTING]
    if not rest:
        return Assessment("unconfirmed")
    level = min((_strength(e, attestors) for e in rest), key=CONFIDENCE_LEVELS.index)
    if today is None:
        return Assessment(level)
    fresh = any(_strength(e, attestors) == level and expires(e) >= today for e in rest)
    return Assessment(level, stale=not fresh)


def confidence(item: Account | Package, attestors: frozenset[str] = frozenset()) -> str:
    """Derive a confidence level from evidence, ignoring how old it is."""
    return assess(item, attestors).confidence


def validate(data: dict[str, Any], schema: dict[str, Any]) -> list[str]:
    """Return schema errors for one crosswalk document, as readable strings."""
    validator = jsonschema.Draft7Validator(schema, format_checker=jsonschema.Draft7Validator.FORMAT_CHECKER)
    errors = sorted(validator.iter_errors(data), key=lambda e: list(e.absolute_path))
    return [f"{'/'.join(str(p) for p in e.absolute_path) or '(root)'}: {e.message}" for e in errors]


def _evidence(data: dict[str, Any]) -> Evidence:
    person = data.get("confirmedWith")
    return Evidence(**{**data, "confirmedWith": Person(**person) if person else None})


def from_dict(data: dict[str, Any]) -> Crosswalk:
    accounts = tuple(
        Account(**{**a, "evidence": tuple(_evidence(e) for e in a["evidence"])}) for a in data["accounts"]
    )
    packages = tuple(
        Package(**{**p, "evidence": tuple(_evidence(e) for e in p["evidence"])}) for p in data.get("packages", [])
    )
    return Crosswalk(identifier=data["identifier"], accounts=accounts, packages=packages)


def load(path: Path, schema: dict[str, Any] | None = None) -> Crosswalk:
    """Load one crosswalk file; raise ValueError if it breaks the schema or its file name."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if schema is not None:
        errors = validate(data, schema)
        if errors:
            raise ValueError(f"{path}: " + "; ".join(errors))
    if data.get("identifier") != path.stem:
        raise ValueError(f"{path}: identifier {data.get('identifier')!r} does not match file name")
    return from_dict(data)


def load_dir(directory: Path, schema: dict[str, Any] | None = None) -> list[Crosswalk]:
    """Load every *.json crosswalk in a directory, sorted by identifier."""
    return [load(p, schema) for p in sorted(directory.glob("*.json"))]


def load_attestors(path: Path, schema: dict[str, Any] | None = None) -> frozenset[str]:
    """Return the GitHub logins listed in an attestors file."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if schema is not None:
        errors = validate(data, schema)
        if errors:
            raise ValueError(f"{path}: " + "; ".join(errors))
    return frozenset(a["login"] for a in data["attestors"])
