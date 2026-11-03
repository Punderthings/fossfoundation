# SPDX-License-Identifier: Apache-2.0
"""Create person records behind human-attested crosswalk evidence, public or private.

Records follow _data/attestations-schema.json. Public records go in this repository's
_data/attestations.json, only for people who agreed to be published; private records go in
the maintainers' private repository. Crosswalk evidence points to either by its opaque
identifier, so it never needs the person's email.
"""

import json
import re
import uuid
from collections.abc import Callable, Iterable
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Final

from fdncrosswalk.crosswalk import validate

TEST_IDENTIFIER: Final[str] = "urn:uuid:00000000-0000-0000-0000-000000000000"
LEGAL_BASIS: Final[str] = "https://gdpr-info.eu/art-6-gdpr/"
DEFAULT_PURPOSE: Final[str] = (
    "Keep contact details for the person who confirmed crosswalk links, so maintainers can re-confirm them later."
)
RETENTION: Final[timedelta] = timedelta(days=365)
CROSSWALK_URL: Final[str] = "https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk/{}.json"
EMAIL: Final[re.Pattern[str]] = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

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
