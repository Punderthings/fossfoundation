"""Read public registry APIs and turn what they show into suggested evidence.

Each probe takes a fetch_json callable so tests can run offline. Probes only suggest
evidence; a person reviews it before it goes into a crosswalk file.
"""

import json
import urllib.request
from collections.abc import Callable
from datetime import date
from typing import Any
from urllib.parse import quote

from fdncrosswalk.crosswalk import Evidence

FetchJson = Callable[[str, dict[str, str]], Any]

PYPI_SIMPLE_JSON = "application/vnd.pypi.simple.v1+json"


def fetch_json(url: str, headers: dict[str, str]) -> Any:
    request = urllib.request.Request(url, headers={"User-Agent": "fdncrosswalk/0.1", **headers})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def docker_hub_org(name: str, fetch: FetchJson = fetch_json, today: str | None = None) -> list[Evidence]:
    """Profile claims and program badge from a Docker Hub organization."""
    observed = today or date.today().isoformat()
    source = f"https://hub.docker.com/v2/orgs/{quote(name, safe='')}/"
    org = fetch(source, {})
    found: list[Evidence] = []
    claims = [f"{k} {org[k]!r}" for k in ("full_name", "company", "profile_url") if org.get(k)]
    if claims:
        found.append(Evidence("profile-claim", source, observed, "Org profile gives " + ", ".join(claims) + "."))
    if org.get("badge"):
        found.append(Evidence("program-badge", source, observed, f"Org carries the Docker Hub badge {org['badge']!r}."))
    return found


def npm_org_packages(scope: str, fetch: FetchJson = fetch_json) -> list[str]:
    """Package names published under an npm org (scope given with or without @)."""
    data = fetch(f"https://registry.npmjs.org/-/org/{quote(scope.lstrip('@'), safe='')}/package", {})
    if not isinstance(data, dict) or "error" in data:
        return []
    return sorted(data)


def pypi_provenance(project: str, fetch: FetchJson = fetch_json, today: str | None = None) -> list[Evidence]:
    """Trusted-publisher repositories for the newest attested file of a PyPI project.

    Returns one publish-provenance item per distinct publisher, or nothing when no file is attested.
    """
    observed = today or date.today().isoformat()
    index = fetch(f"https://pypi.org/simple/{quote(project, safe='')}/", {"Accept": PYPI_SIMPLE_JSON})
    attested = [f for f in index.get("files", []) if f.get("provenance")]
    if not attested:
        return []
    newest = attested[-1]
    provenance = fetch(newest["provenance"], {})
    found: list[Evidence] = []
    seen: set[tuple[str, str]] = set()
    for bundle in provenance.get("attestation_bundles", []):
        publisher = bundle.get("publisher", {})
        key = (publisher.get("kind", ""), publisher.get("repository", ""))
        if not key[1] or key in seen:
            continue
        seen.add(key)
        found.append(
            Evidence(
                "publish-provenance",
                newest["provenance"],
                observed,
                f"{newest['filename']} is published by {key[0]} trusted publishing from {key[1]}"
                f" (workflow {publisher.get('workflow')}).",
            )
        )
    return found
