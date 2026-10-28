"""Build ecosyste.ms API lookups for crosswalk accounts.

Paths follow the published OpenAPI specs (repos, packages, sponsors, papers). Every URL carries
mailto, read from the ECOSYSTEMS_MAILTO environment variable, so requests go to the ecosyste.ms
polite pool, as the project requires. The address is never stored in this repository.
"""

import os
from typing import Final
from urllib.parse import quote, urlencode, urlsplit

from fdncrosswalk.crosswalk import Account, Package

MAILTO_ENV: Final[str] = "ECOSYSTEMS_MAILTO"
MAILTO: Final[str] = os.environ.get(MAILTO_ENV, "")

REPOS_API: Final[str] = "https://repos.ecosyste.ms/api/v1"
PACKAGES_API: Final[str] = "https://packages.ecosyste.ms/api/v1"
SPONSORS_API: Final[str] = "https://sponsors.ecosyste.ms/api/v1"
PAPERS_API: Final[str] = "https://papers.ecosyste.ms/api/v1"
REPOS_SITE: Final[str] = "https://repos.ecosyste.ms"
PACKAGES_SITE: Final[str] = "https://packages.ecosyste.ms"

# Crosswalk platform -> ecosyste.ms repos host name.
REPO_HOSTS: Final[dict[str, str]] = {
    "github.com": "GitHub",
    "gitlab.com": "GitLab",
    "codeberg.org": "Codeberg",
}

# Registries where ecosyste.ms has a namespace concept matching our "namespace" or "organization".
NAMESPACE_REGISTRIES: Final[frozenset[str]] = frozenset({"npmjs.org", "repo1.maven.org", "hub.docker.com"})

# purl type -> ecosyste.ms registry name (packages) or host name (repos, for repository purls).
PURL_REGISTRIES: Final[dict[str, str]] = {
    "pypi": "pypi.org",
    "npm": "npmjs.org",
    "maven": "repo1.maven.org",
    "gem": "rubygems.org",
    "cargo": "crates.io",
    "docker": "hub.docker.com",
}
PURL_HOSTS: Final[dict[str, str]] = {"github": "GitHub", "gitlab": "GitLab"}

# purl type -> ecosystem name used by papers.ecosyste.ms projects.
PAPERS_ECOSYSTEMS: Final[dict[str, str]] = {"pypi": "pypi", "npm": "npm", "cran": "cran"}


def _url(base: str, *segments: str, mailto: str = MAILTO) -> str:
    path = "/".join(quote(s, safe="") for s in segments)
    return f"{base}/{path}?{urlencode({'mailto': mailto})}" if mailto else f"{base}/{path}"


def _query(base: str, path: str, mailto: str, **params: str) -> str:
    return f"{base}/{path}?{urlencode({**params, 'mailto': mailto} if mailto else params)}"


def purl_type(purl: str) -> str:
    """Return the type of a purl, e.g. pypi for pkg:pypi/numpy."""
    return purl.removeprefix("pkg:").split("/", 1)[0]


def owner_host(account: Account) -> str | None:
    """ecosyste.ms repos host name for a code host account, or None for a registry account."""
    if account.host:
        return urlsplit(account.host).hostname
    return REPO_HOSTS.get(account.platform)


def page_url(account: Account) -> str | None:
    """Human-readable ecosyste.ms page for an account, used as schema.org sameAs in exports."""
    host = owner_host(account)
    if host:
        return f"{REPOS_SITE}/hosts/{quote(host, safe='')}/owners/{quote(account.name, safe='')}"
    if account.platform in NAMESPACE_REGISTRIES:
        return f"{PACKAGES_SITE}/registries/{account.platform}/namespaces/{quote(account.name, safe='')}"
    return None


def package_lookup_urls(package: Package, mailto: str = MAILTO) -> dict[str, str]:
    """Return {index name: URL} for the ecosyste.ms records that describe this package or repository."""
    kind = purl_type(package.purl)
    if kind in PURL_HOSTS:
        urls = {"repos": _query(REPOS_API, "repositories/lookup", mailto, purl=package.purl)}
    else:
        urls = {"packages": _query(PACKAGES_API, "packages/lookup", mailto, purl=package.purl)}
    if kind in PAPERS_ECOSYSTEMS:
        name = package.purl.split("/", 1)[1]
        urls["papers"] = _url(PAPERS_API, "projects", PAPERS_ECOSYSTEMS[kind], name, mailto=mailto)
    return urls


def lookup_urls(account: Account, mailto: str = MAILTO) -> dict[str, str]:
    """Return {index name: URL} for the ecosyste.ms records that describe this account.

    An empty dict means ecosyste.ms has no matching record type (for example PyPI orgs).
    """
    host = owner_host(account)
    if host:
        urls = {"repos": _url(REPOS_API, "hosts", host, "owners", account.name, mailto=mailto)}
        if account.platform == "github.com":
            urls["sponsors"] = _url(SPONSORS_API, "accounts", account.name, mailto=mailto)
        return urls
    if account.platform in NAMESPACE_REGISTRIES:
        return {
            "packages": _url(
                PACKAGES_API, "registries", account.platform, "namespaces", account.name, mailto=mailto
            )
        }
    if account.platform == "rubygems.org" and account.kind == "user":
        return {
            "packages": _url(
                PACKAGES_API, "registries", account.platform, "maintainers", account.name, mailto=mailto
            )
        }
    return {}
