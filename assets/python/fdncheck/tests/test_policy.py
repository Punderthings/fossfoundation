# SPDX-License-Identifier: Apache-2.0
import pytest
from conftest import snap

from fdncheck.detect.policy import decide_url, normalize, same_site
from fdncheck.fetch import Snapshot


@pytest.mark.parametrize(
    ("a", "b", "equal"),
    [
        ("https://Example.org/about/", "https://example.org/about", True),
        ("https://example.org:443/x", "https://example.org/x", True),
        ("https://example.org/x#frag", "https://example.org/x", True),
        ("http://example.org/x", "https://example.org/x", False),
        ("https://example.org/x?a=1", "https://example.org/x", False),
    ],
)
def test_normalize(a, b, equal):
    assert (normalize(a) == normalize(b)) is equal


@pytest.mark.parametrize(
    ("a", "b", "same"),
    [
        ("https://example.org/", "https://www.example.org/x", True),
        ("https://example.org/", "https://docs.example.org/", True),
        ("https://www.example.org/", "https://example.net/", False),
        ("https://example.org/", "https://notexample.org/", False),
    ],
)
def test_same_site(a, b, same):
    assert same_site(a, b) is same


def decide(current, snapshot, needs_js=False):
    return decide_url("acme", "website", current, snapshot, needs_js)


def test_ok_and_needs_javascript():
    assert decide("https://a.org/", snap("https://a.org/")).rule == "ok"
    assert decide("https://a.org/", snap("https://a.org/"), needs_js=True).rule == "ok-needs-javascript"


def test_permanent_same_site_redirect_updates_and_keeps_fragment():
    f = decide(
        "http://a.org/x#top",
        snap("http://a.org/x#top", redirects=[(301, "https://a.org/y"), (308, "https://www.a.org/y")]),
    )
    assert (f.action, f.rule, f.proposed) == ("update", "redirect-permanent-same-site", "https://www.a.org/y#top")


def test_equivalent_redirect_is_fine():
    f = decide("https://a.org/x", snap("https://a.org/x", redirects=[(301, "https://a.org/x/")]))
    assert (f.action, f.rule) == ("ok", "ok-equivalent-redirect")


def test_any_temporary_hop_is_only_flagged():
    f = decide(
        "https://a.org/x", snap("https://a.org/x", redirects=[(301, "https://a.org/y"), (302, "https://a.org/z")])
    )
    assert (f.action, f.rule, f.proposed) == ("flag", "redirect-temporary", "https://a.org/z")


def test_off_site_permanent_redirect_is_only_flagged():
    f = decide("https://a.org/x", snap("https://a.org/x", redirects=[(301, "https://b.net/x")]))
    assert (f.action, f.rule) == ("flag", "redirect-off-site")


@pytest.mark.parametrize(
    ("status", "action", "rule"),
    [
        (404, "flag", "not-found"),
        (410, "flag", "not-found"),
        (500, "flag", "http-error"),
        (418, "flag", "http-error"),
        (403, "unchecked", "blocked"),
        (429, "unchecked", "blocked"),
        (503, "unchecked", "blocked"),
    ],
)
def test_error_statuses(status, action, rule):
    f = decide("https://a.org/", snap("https://a.org/", status=status))
    assert (f.action, f.rule, f.proposed) == (action, rule, None)


@pytest.mark.parametrize(
    ("error", "action", "rule"),
    [
        ("robots-disallowed", "unchecked", "robots-disallowed"),
        ("timeout", "unchecked", "fetch-error"),
        ("robots.txt answered HTTP 500", "unchecked", "fetch-error"),
        ("too-many-redirects", "flag", "redirect-loop"),
    ],
)
def test_fetch_errors(error, action, rule):
    f = decide("https://a.org/", Snapshot("https://a.org/", "https://a.org/", 0, "2026-11-15T00:00:00Z", error=error))
    assert (f.action, f.rule) == (action, rule)
