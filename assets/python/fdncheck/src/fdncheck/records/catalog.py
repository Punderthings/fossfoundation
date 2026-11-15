# SPDX-License-Identifier: Apache-2.0
"""The field catalog, read from the ``x-check`` keyword on each property of foundations-schema.json.

The schema says what kind of check each field gets; this module says what fdncheck may
do for each kind (``POLICY``). Classes follow the plan in
_prompts/2026-11-14-foundation-website-checker-plan.md:

url        (A) fetched; a permanent same-site redirect may update the value.
fact       (C) a short fact (name, date, identifier): flag only (phase 2).
count      (D) a number: flag only, from per-foundation selectors (phase 2).
choice     (E) an enumerated or yes/no value: never inferred.
text       (F) descriptive text: never edited; change-watch only (phase 5).
reference  (G) an identifier that must exist in this site's data.

Discovery of missing URLs (class B, phase 5) uses the url fields. Moving a field to
another class is a one-line, reviewed change to the schema; letting a class update
values is a reviewed change to ``POLICY``.
"""

from dataclasses import dataclass

KEYWORD = "x-check"


@dataclass(frozen=True)
class Policy:
    may_update: bool  # may fdncheck change values of this class without a person's edit?
    checked_in_phase: int | None  # first phase that checks it; None = never


POLICY: dict[str, Policy] = {
    "url": Policy(True, 1),
    "fact": Policy(False, 2),
    "count": Policy(False, 2),
    "choice": Policy(False, None),
    "text": Policy(False, 5),
    "reference": Policy(False, 1),
}

# jjresolver collections that are folders of this repository
LOCAL_COLLECTIONS = {"sponsorships": "_sponsorships", "entities": "_entities", "foundations": "_foundations"}


@dataclass(frozen=True)
class FieldSpec:
    name: str
    check: str  # an x-check value, a key of POLICY
    joins: str | None = None  # reference fields: the folder the value must name, if local

    @property
    def may_update(self) -> bool:
        return POLICY[self.check].may_update

    @property
    def checked_in_phase(self) -> int | None:
        return POLICY[self.check].checked_in_phase


def _format(prop: dict) -> str:
    return prop.get("format") or (prop.get("items") or {}).get("format") or ""


def _joins(prop: dict) -> str | None:
    """``jjresolver~sponsorships~identifier~name~/sponsorships/`` names the sponsorships collection."""
    parts = _format(prop).split("~")
    if parts[0] == "jjresolver" and len(parts) > 1:
        return LOCAL_COLLECTIONS.get(parts[1])
    return None


class Catalog:
    """Every schema property with its check class, in schema order."""

    def __init__(self, schema: dict) -> None:
        self.schema = schema
        props = schema.get("properties", {})
        self.fields: dict[str, FieldSpec] = {
            name: FieldSpec(name, prop[KEYWORD], _joins(prop))
            for name, prop in props.items()
            if prop.get(KEYWORD) in POLICY
        }

    def __getitem__(self, name: str) -> FieldSpec:
        return self.fields[name]

    def __iter__(self):
        return iter(self.fields.values())

    def names(self, check: str) -> list[str]:
        return [spec.name for spec in self if spec.check == check]

    def problems(self) -> list[str]:
        """Ways the schema's x-check values disagree with its types and formats; a test keeps this empty."""
        found: list[str] = []
        for name, prop in self.schema.get("properties", {}).items():
            check = prop.get(KEYWORD)
            fmt = _format(prop)
            if check is None:
                found.append(f"{name}: no {KEYWORD}")
                continue
            if check not in POLICY:
                found.append(f"{name}: unknown {KEYWORD} {check!r}")
                continue
            if (fmt == "url") != (check == "url"):
                found.append(f"{name}: {KEYWORD} {check!r} but format {fmt or 'none'!r}")
            if (prop.get("type") == "number") != (check == "count"):
                found.append(f"{name}: {KEYWORD} {check!r} but type {prop.get('type')!r}")
            if fmt.startswith("jjresolver") and check != "reference":
                found.append(f"{name}: {KEYWORD} {check!r} but format {fmt!r} names another collection")
            if fmt == "date" and check != "fact":
                found.append(f"{name}: {KEYWORD} {check!r} but format 'date'")
        return found

    def url_targets(self, data: dict) -> list[tuple[str, str]]:
        """Every (field, url) pair to fetch, in schema order; list-valued fields give one pair per item.

        Values that are not http(s) URLs (``mailto:``, free text) are left out: they can't be fetched.
        """
        targets: list[tuple[str, str]] = []
        for name in self.names("url"):
            value = data.get(name)
            for item in value if isinstance(value, list) else [value]:
                if isinstance(item, str) and item.strip().lower().startswith(("http://", "https://")):
                    targets.append((name, item.strip()))
        return targets
