# SPDX-License-Identifier: Apache-2.0
"""Create person records behind human-attested crosswalk evidence, and add or renew that evidence.

Records follow _data/attestations-schema.json. Public records go in this repository's
_data/attestations.json, only for people who agreed to be published; private records go in
the maintainers' private repository. Crosswalk evidence points to either by its opaque
identifier, so it never needs the person's email.
"""

import json
import re
import uuid
from collections.abc import Callable, Iterable
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Final

from fdncrosswalk.crosswalk import CONTRADICTING, HUMAN_ATTESTED, PENDING_SOURCE, evidence_from_dict, expires, validate

TEST_IDENTIFIER: Final[str] = "urn:uuid:00000000-0000-0000-0000-000000000000"
LEGAL_BASIS: Final[str] = "https://gdpr-info.eu/art-6-gdpr/"
DEFAULT_PURPOSE: Final[str] = (
    "Keep contact details for the person who confirmed crosswalk links, so maintainers can re-confirm them later."
)
RETENTION: Final[timedelta] = timedelta(days=365)
CROSSWALK_URL: Final[str] = "https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk/{}.json"
EMAIL: Final[re.Pattern[str]] = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")
IDENTIFIER: Final[re.Pattern[str]] = re.compile(r"^urn:uuid:[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
# Human attestations that expire within this window are listed for renewal before they go stale.
RENEW_WINDOW: Final[timedelta] = timedelta(days=60)

Ask = Callable[[str], str]
Say = Callable[[str], None]


def new_identifier() -> str:
    """A random, opaque identifier: never derived from the person's details."""
    return f"urn:uuid:{uuid.uuid4()}"


def methods(schema: dict[str, Any]) -> list[str]:
    """Consent methods allowed by the attestations schema."""
    consent = schema["definitions"]["attestation"]["properties"]["consent"]
    return list(consent["properties"]["method"]["enum"])


def confirmed_with(record: dict[str, Any]) -> dict[str, str]:
    """The confirmedWith object to put in crosswalk evidence: no email or name."""
    return {k: record[k] for k in ("identifier", "roleName", "memberOf")}


def read_records(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"attestations": []}
    return json.loads(path.read_text(encoding="utf-8"))


def add_record(path: Path, record: dict[str, Any], schema: dict[str, Any]) -> None:
    """Append one record to an attestations file, refusing duplicates and schema errors."""
    data = read_records(path)
    for old in data["attestations"]:
        if old["identifier"] == record["identifier"]:
            raise ValueError(f"{path}: identifier {record['identifier']} is already used")
        if old["email"].lower() == record["email"].lower():
            raise ValueError(f"{path}: {old['identifier']} already has this email; edit that record instead")
    data["attestations"].append(record)
    errors = validate(data, schema)
    if errors:
        raise ValueError(f"{path}: " + "; ".join(errors))
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _question(ask: Ask, say: Say, text: str, default: str | None = None, check=None, optional=False) -> str:
    prompt = f"{text} [{default}]: " if default else (f"{text} (Enter to skip): " if optional else f"{text}: ")
    while True:
        answer = ask(prompt).strip() or (default or "")
        if not answer and optional:
            return ""
        problem = "an answer is needed" if not answer else (check(answer) if check else None)
        if not problem:
            return answer
        say(f"  {problem}")


def yes(ask: Ask, say: Say, text: str, default: bool) -> bool:
    answer = _question(ask, say, f"{text} (y/n)", "y" if default else "n", lambda a: None if a[0] in "yYnN" else "y or n")
    return answer[0] in "yY"


def _date(answer: str) -> str | None:
    try:
        date.fromisoformat(answer)
    except ValueError:
        return "use YYYY-MM-DD"
    return None


def interview(
    ask: Ask,
    say: Say,
    *,
    schema: dict[str, Any],
    foundations: Iterable[str],
    attestors: Iterable[str],
    today: date,
    visibility: str | None = None,
    test: bool = False,
) -> dict[str, Any]:
    """Ask the questions a record needs and return it, not yet saved."""
    foundations, attestors = set(foundations), set(attestors)
    say("Adding a person who confirmed crosswalk links. Only record what they agreed to.")
    if visibility is None:
        visibility = _question(
            ask, say, "Store the record public or private?", "private",
            lambda a: None if a in ("public", "private") else "public or private",
        )
    publish = False
    if visibility == "public":
        publish = yes(ask, say, "Did the person agree to publish their email, role and name in the public repo?", False)
        if not publish:
            say("  Then the record is private: it goes only in the private repository.")
            visibility = "private"
    record: dict[str, Any] = {
        "identifier": TEST_IDENTIFIER if test else new_identifier(),
        "visibility": visibility,
    }
    if test:
        record["testRecord"] = True
    name = _question(ask, say, "Their name", optional=True)
    if name:
        record["name"] = name
    record["email"] = _question(ask, say, "Their email", check=lambda a: None if EMAIL.match(a) else "not an email")
    record["roleName"] = _question(ask, say, "Their role at the organization, e.g. VP Infrastructure")
    record["memberOf"] = _question(
        ask, say, "Organization identifier (a _foundations file name, e.g. asf)",
        check=lambda a: None if a in foundations else "no _foundations file with that identifier",
    )
    record["recordedBy"] = _question(ask, say, "Your GitHub login (the attestor)")
    if record["recordedBy"] not in attestors:
        say("  Note: you are not in _data/attestors.json, so your attestations will count as probable, not confirmed.")
    record["dateCreated"] = today.isoformat()
    options = methods(schema)
    for number, method in enumerate(options, 1):
        say(f"  {number}. {method}")
    choice = _question(
        ask, say, "How did they give consent? (number)", check=lambda a: None if a.isdigit() and 0 < int(a) <= len(options) else "pick a number"
    )
    consent: dict[str, Any] = {
        "dateGiven": _question(ask, say, "Date consent was given", today.isoformat(), _date),
        "method": options[int(choice) - 1],
    }
    evidence = _question(ask, say, "Where can the consent be found again (mail archive link, ticket)?", optional=True)
    if evidence:
        consent["evidence"] = evidence
    consent["purpose"] = _question(ask, say, "What did they agree we may use it for?", DEFAULT_PURPOSE)
    consent["legalBasis"] = LEGAL_BASIS
    if publish:
        consent["publish"] = True
    record["consent"] = consent
    record["retainUntil"] = _question(ask, say, "Review this record by", (today + RETENTION).isoformat(), _date)
    used = _question(
        ask, say, "Crosswalk files it supports (comma-separated foundation identifiers)", record["memberOf"], optional=True
    )
    if used:
        record["usedIn"] = [CROSSWALK_URL.format(u.strip()) for u in used.split(",") if u.strip()]
    return record


# Evidence: add a human-attested item to a crosswalk file, and renew old ones.


def evidence_methods(schema: dict[str, Any]) -> list[str]:
    """Evidence methods allowed by the crosswalk schema."""
    return list(schema["definitions"]["evidence"]["properties"]["method"]["enum"])


def targets(data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    """Accounts and packages of one crosswalk document, by label: <platform>/<name> or the purl."""
    found = {f"{a['platform']}/{a['name']}": a for a in data["accounts"]}
    found.update({p["purl"]: p for p in data.get("packages", [])})
    return found


def evidence_item(
    *,
    creator: str,
    method: str,
    confirmed_with: dict[str, str],
    observed: str,
    detail: str,
    source: str = PENDING_SOURCE,
    supersedes: bool = False,
) -> dict[str, Any]:
    """One human-attested evidence item, in the key order of the schema."""
    item: dict[str, Any] = {"type": HUMAN_ATTESTED, "source": source, "observed": observed, "detail": detail,
                            "creator": creator, "method": method, "confirmedWith": confirmed_with}
    if supersedes:
        item["supersedes"] = True
    return item


def save_crosswalk(path: Path, data: dict[str, Any], schema: dict[str, Any]) -> None:
    """Write a crosswalk document in the repository's format, refusing schema errors."""
    errors = validate(data, schema)
    if errors:
        raise ValueError(f"{path}: " + "; ".join(errors))
    path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _pick(ask: Ask, say: Say, text: str, options: list[str], default: str | None = None) -> str:
    for number, option in enumerate(options, 1):
        say(f"  {number}. {option}")
    shown = str(options.index(default) + 1) if default in options else None
    choice = _question(
        ask, say, f"{text} (number)", shown, lambda a: None if a.isdigit() and 0 < int(a) <= len(options) else "pick a number"
    )
    return options[int(choice) - 1]


def evidence_interview(
    ask: Ask,
    say: Say,
    *,
    data: dict[str, Any],
    methods: list[str],
    attestors: Iterable[str],
    people: dict[str, dict[str, Any]],
    new_person: Callable[[], dict[str, Any]],
    today: date,
    target: str | None = None,
    creator: str | None = None,
) -> tuple[str, dict[str, Any]]:
    """Ask what a human-attested evidence item needs; return the target label and the item, not yet saved."""
    found = targets(data)
    if target is None:
        say(f"Accounts and packages in the {data['identifier']} crosswalk:")
        target = _pick(ask, say, "Which one did you confirm?", list(found))
    elif target not in found:
        raise ValueError(f"{data['identifier']}: no account or package {target!r}; use <platform>/<name> or a purl")
    creator = creator or _question(ask, say, "Your GitHub login (the attestor)")
    if creator not in set(attestors):
        say("  Note: you are not in _data/attestors.json, so this attestation will count as probable, not confirmed.")
    say("How was it confirmed?")
    method = _pick(ask, say, "Method", methods)
    observed = _question(ask, say, "Date it was confirmed", today.isoformat(), _date)
    identifier = _question(
        ask, say, "Identifier of the person who confirmed it; skip to create their record now", optional=True,
        check=lambda a: None if IDENTIFIER.match(a) else "use urn:uuid:<uuid>",
    )
    if not identifier:
        person = confirmed_with(new_person())
    elif identifier in people:
        person = confirmed_with(people[identifier])
    else:
        say("  That record is not in the files available here, so give its role and organization.")
        person = {
            "identifier": identifier,
            "roleName": _question(ask, say, "Their role at the organization"),
            "memberOf": _question(ask, say, "Organization identifier", data["identifier"]),
        }
    detail = _question(ask, say, "One sentence on what they confirmed")
    source = _question(ask, say, "Pull request or signed commit URL", PENDING_SOURCE)
    supersedes = False
    if any(e["type"] == CONTRADICTING for e in found[target]["evidence"]):
        supersedes = yes(ask, say, "This link has contradiction evidence. Does your attestation override it?", False)
        if supersedes:
            say("  Explain why in the detail sentence, so the override stays on record.")
    item = evidence_item(creator=creator, method=method, confirmed_with=person, observed=observed, detail=detail,
                         source=source, supersedes=supersedes)
    return target, item


@dataclass(frozen=True)
class Due:
    """A human-attested evidence item that is stale or will be within the renewal window."""

    foundation: str
    target: str
    evidence: dict[str, Any]
    expires: date
    stale: bool


def due(documents: Iterable[dict[str, Any]], today: date, creator: str | None = None,
        window: timedelta = RENEW_WINDOW) -> list[Due]:
    """Human-attested items to renew, oldest expiry first; only one attestor's when creator is given."""
    found = []
    for data in documents:
        for label, entry in targets(data).items():
            for item in entry["evidence"]:
                if item["type"] != HUMAN_ATTESTED or (creator and item.get("creator") != creator):
                    continue
                ends = expires(evidence_from_dict(item))
                if ends is not None and ends < today + window:
                    found.append(Due(data["identifier"], label, item, ends, ends < today))
    return sorted(found, key=lambda d: (d.expires, d.foundation, d.target))


def renew(ask: Ask, say: Say, items: Iterable[Due], *, methods: list[str], today: date) -> list[Due]:
    """Ask about each item; update the ones confirmed again in place, and return them."""
    renewed = []
    for d in items:
        state = "stale since" if d.stale else "goes stale"
        who = d.evidence["confirmedWith"].get("roleName", "")
        say(f"{d.foundation}: {d.target}, confirmed with {who}, {state} {d.expires.isoformat()}")
        if not yes(ask, say, "Did you confirm it again?", False):
            continue
        item = d.evidence
        item["observed"] = _question(ask, say, "Date it was confirmed again", today.isoformat(), _date)
        item["method"] = _pick(ask, say, "Method", methods, item.get("method"))
        item.pop("validThrough", None)
        item["source"] = PENDING_SOURCE
        renewed.append(d)
    return renewed
