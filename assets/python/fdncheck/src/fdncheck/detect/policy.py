# SPDX-License-Identifier: Apache-2.0
"""Rules for URL fields (class A): normalize URLs and decide what a fetch means for a value."""

from urllib.parse import urlsplit, urlunsplit

from fdncheck.detect import Finding
from fdncheck.fetch import Snapshot

PERMANENT = frozenset({301, 308})
BLOCKING = frozenset({401, 403, 429, 503})  # usually bot protection or rate limits, not a missing page
GONE = frozenset({404, 410})


def normalize(url: str) -> str:
    """Compare-only form: lower-case scheme and host, no default port, no fragment, no trailing slash.

    http and https stay different, because moving to https is a real change.
    """
    parts = urlsplit(url.strip())
    scheme = parts.scheme.lower()
    host = (parts.hostname or "").lower()
    port = parts.port
    netloc = host if port is None or (scheme, port) in (("http", 80), ("https", 443)) else f"{host}:{port}"
    path = parts.path.rstrip("/")
    return urlunsplit((scheme, netloc, path, parts.query, ""))


def _site(host: str) -> str:
    host = host.lower().rstrip(".")
    return host.removeprefix("www.")


def same_site(a: str, b: str) -> bool:
    """True when both URLs are on the same host, ignoring a leading ``www.``, or one is a subdomain of the other.

    This approximates "same registrable domain" without a public-suffix list, and errs
    on the side of flagging: example.org and docs.example.org match, example.org and
    example.net don't.
    """
    ha, hb = _site(urlsplit(a).hostname or ""), _site(urlsplit(b).hostname or "")
    return bool(ha and hb) and (ha == hb or ha.endswith("." + hb) or hb.endswith("." + ha))


def _with_fragment(original: str, final: str) -> str:
    fragment = urlsplit(original).fragment
    if fragment and not urlsplit(final).fragment:
        return f"{final}#{fragment}"
    return final


def decide_url(identifier: str, field: str, current: str, snapshot: Snapshot, needs_js: bool = False) -> Finding:
    """Decide what one fetch of a URL field means. The order of the checks is the policy."""

    def finding(action, rule, reason, proposed=None) -> Finding:
        return Finding(identifier, field, current, action, rule, reason, proposed, snapshot)

    if snapshot.error == "robots-disallowed":
        return finding("unchecked", "robots-disallowed", "robots.txt asks automated clients not to fetch it")
    if snapshot.error == "too-many-redirects":
        return finding("flag", "redirect-loop", "too many redirects")
    if snapshot.error:
        return finding("unchecked", "fetch-error", f"no response ({snapshot.error})")
    status = snapshot.status
    if status in BLOCKING:
        return finding("unchecked", "blocked", f"HTTP {status}, probably blocking automated clients")
    if status in GONE:
        return finding("flag", "not-found", f"HTTP {status}; not removed")
    if status >= 400:
        return finding("flag", "http-error", f"HTTP {status}; not removed")
    if not snapshot.redirects:
        if needs_js:
            return finding("ok", "ok-needs-javascript", f"HTTP {status}; content needs JavaScript (phase 2)")
        return finding("ok", "ok", f"HTTP {status}")
    final = _with_fragment(current, snapshot.final_url)
    if normalize(final) == normalize(current):
        return finding("ok", "ok-equivalent-redirect", "redirects to an equivalent URL")
    statuses = [hop[0] for hop in snapshot.redirects]
    hops = ", ".join(str(s) for s in statuses)
    if not all(s in PERMANENT for s in statuses):
        return finding("flag", "redirect-temporary", f"temporary redirect ({hops}) to {final}; not changed", final)
    if not same_site(current, final):
        return finding("flag", "redirect-off-site", f"permanent redirect ({hops}) to another site: {final}", final)
    return finding("update", "redirect-permanent-same-site", f"permanent redirect ({hops}) on the same site", final)
