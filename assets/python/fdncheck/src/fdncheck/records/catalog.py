# SPDX-License-Identifier: Apache-2.0
"""The field catalog: for every field in foundations-schema.json, how fdncheck may check it.

Classes follow the plan in _prompts/2026-11-14-foundation-website-checker-plan.md:

A  URL fields: fetched; a permanent same-site redirect may update the value.
B  Discovery of missing URLs (phase 5; not a separate set of fields).
C  Structured facts: flag only, from Schema.org markup or narrow patterns (phase 2).
D  Counts: flag only, from per-foundation selectors (phase 2).
E  Enumerations and yes/no values: never inferred.
F  Descriptive text: never edited; change-watch only (phase 5).
G  Joins: referenced identifiers must exist.

Moving a field from flag to update is a one-line, reviewed change to this table.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class FieldSpec:
    name: str
    cls: str  # "A".."G"
    may_update: bool  # may fdncheck change this value without a person's edit?
    checked_in_phase: int | None  # first phase that checks it; None = never
    joins: str | None = None  # class G: collection folder the value must name


URL_FIELDS = (
    "website",
    "contacturl",
    "boardurl",
    "teamurl",
    "missionurl",
    "bylawsurl",
    "projectsList",
    "eventurl",
    "budgeturl",
    "donateurl",
    "sponsorurl",
    "securityurl",
    "ethicsPolicy",
    "conducturl",
    "conductEvents",
    "conductProjects",
    "diversityPolicy",
    "brandPolicy",
    "brandUse",
    "logo",
)
FACT_FIELDS = (
    "commonName",
    "legalName",
    "foundingDate",
    "dissolutionDate",
    "addressCountry",
    "addressRegion",
    "taxID",
    "taxIDLocal",
    "wikidataId",
)
COUNT_FIELDS = ("boardSize", "numberOfEmployees")
ENUM_FIELDS = (
    "newProjects",
    "softwareType",
    "boardType",
    "nonprofitStatus",
    "budgetUsd",
    "budgetYear",
    "budgetTransparent",
    "funding",
    "licenses",
    "claPolicy",
    "brandReg",
    "logoReg",
)
TEXT_FIELDS = (
    "description",
    "governanceOrg",
    "governanceTech",
    "projectsNotable",
    "projectsServices",
    "sponsorList",
    "conductReport",
    "diversityDescription",
    "brandPrimary",
    "brandSecondary",
    "brandComments",
)

CATALOG: dict[str, FieldSpec] = {}
for _name in URL_FIELDS:
    CATALOG[_name] = FieldSpec(_name, "A", True, 1)
for _name in FACT_FIELDS:
    CATALOG[_name] = FieldSpec(_name, "C", False, 2)
for _name in COUNT_FIELDS:
    CATALOG[_name] = FieldSpec(_name, "D", False, 2)
for _name in ENUM_FIELDS:
    CATALOG[_name] = FieldSpec(_name, "E", False, None)
for _name in TEXT_FIELDS:
    CATALOG[_name] = FieldSpec(_name, "F", False, 5)
CATALOG["identifier"] = FieldSpec("identifier", "G", False, 1)
CATALOG["sponsorships"] = FieldSpec("sponsorships", "G", False, 1, joins="_sponsorships")
CATALOG["subOrganization"] = FieldSpec("subOrganization", "G", False, 1, joins="_entities")
CATALOG["conductSource"] = FieldSpec("conductSource", "G", False, None)  # ids at opensourceconduct.com
CATALOG["conductLinked"] = FieldSpec("conductLinked", "E", False, None)
CATALOG["fiscalHost"] = FieldSpec("fiscalHost", "E", False, None)  # not in the schema yet; used by records


def url_targets(data: dict) -> list[tuple[str, str]]:
    """Every (field, url) pair to fetch, in catalog order; list-valued fields give one pair per item.

    Values that are not http(s) URLs (``mailto:``, free text) are left out: they can't be fetched.
    """
    targets: list[tuple[str, str]] = []
    for name in URL_FIELDS:
        value = data.get(name)
        for item in value if isinstance(value, list) else [value]:
            if isinstance(item, str) and item.strip().lower().startswith(("http://", "https://")):
                targets.append((name, item.strip()))
    return targets
