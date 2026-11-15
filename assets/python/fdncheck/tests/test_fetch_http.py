# SPDX-License-Identifier: Apache-2.0
"""HttpFetcher with a fake transport, and urllib_transport with a fake opener: no network."""

import io
import urllib.error
from email.message import Message

import pytest

from fdncheck.fetch import http
from fdncheck.fetch.http import USER_AGENT, FetchError, HttpFetcher, Response

ROBOTS_OK = "User-agent: *\nDisallow: /private/\n"


class Site:
    """A fake transport: routes are full URLs mapped to a Response or a FetchError to raise."""

    def __init__(self, routes: dict, robots=(200, ROBOTS_OK)):
        self.routes = routes
        self.robots = robots
        self.seen: list[tuple[str, dict]] = []

    def __call__(self, url, headers, timeout, max_bytes):
        self.seen.append((url, dict(headers)))
        if url.endswith("/robots.txt"):
            return Response(self.robots[0], {}, self.robots[1].encode())
        route = self.routes.get(url, Response(404))
        if isinstance(route, Exception):
            raise route
        if len(route.body) > max_bytes:
            return Response(route.status, route.headers, route.body[:max_bytes], True)
        return route

    def paths(self):
        return [url.split("/", 3)[3] for url, _ in self.seen]


def redirect(status, location):
    return Response(status, {"location": location})


def fetcher(site, **kw):
    kw.setdefault("sleep", lambda s: None)
    return HttpFetcher(transport=site, now=lambda: "2026-11-15T12:00:00Z", **kw)


def test_redirect_chain_is_recorded_with_relative_locations():
    site = Site(
        {
            "http://a.org/x": redirect(301, "https://a.org/x"),
            "https://a.org/x": redirect(308, "/y"),
            "https://a.org/y": Response(200, {"content-type": "text/html"}, b"<title>Y</title>"),
        }
    )
    s = fetcher(site).get("http://a.org/x")
    assert s.redirects == ((301, "https://a.org/x"), (308, "https://a.org/y"))
    assert (s.final_url, s.status, s.error, s.fetched_at) == ("https://a.org/y", 200, None, "2026-11-15T12:00:00Z")
    assert (s.body, s.content_type) == (b"<title>Y</title>", "text/html")
    assert all(h["User-Agent"] == USER_AGENT for _, h in site.seen)


def test_robots_disallow_stops_the_fetch():
    site = Site({"https://a.org/private/x": Response(200)})
    assert fetcher(site).get("https://a.org/private/x").error == "robots-disallowed"
    assert site.paths() == ["robots.txt"]


def test_missing_robots_allows_and_is_fetched_once_per_origin():
    site = Site({"https://a.org/1": Response(200), "https://a.org/2": Response(200)}, robots=(404, ""))
    f = fetcher(site)
    assert f.get("https://a.org/1").status == 200
    assert f.get("https://a.org/2").status == 200
    assert site.paths() == ["robots.txt", "1", "2"]


def test_robots_server_error_and_unreachable_are_reported_not_disallowed():
    assert fetcher(Site({}, robots=(500, ""))).get("https://a.org/").error == "robots.txt answered HTTP 500"

    class Down(Site):
        def __call__(self, url, headers, timeout, max_bytes):
            raise FetchError("URLError: [Errno -2] Name or service not known")

    error = fetcher(Down({})).get("https://a.org/").error
    assert error == "robots.txt unreachable (URLError: [Errno -2] Name or service not known)"


def test_robots_can_be_ignored_for_testing():
    site = Site({"https://a.org/private/x": Response(200)})
    assert fetcher(site, obey_robots=False).get("https://a.org/private/x").status == 200
    assert site.paths() == ["private/x"]


def test_http_errors_are_data():
    s = fetcher(Site({"https://a.org/gone": Response(410)})).get("https://a.org/gone")
    assert (s.status, s.error) == (410, None)


def test_a_redirect_without_location_is_the_final_response():
    s = fetcher(Site({"https://a.org/x": Response(302)})).get("https://a.org/x")
    assert (s.status, s.redirects) == (302, ())


def test_transport_errors_become_snapshots():
    site = Site({"https://a.org/slow": FetchError("timeout"), "https://a.org/down": FetchError("URLError: refused")})
    f = fetcher(site)
    assert f.get("https://a.org/slow").error == "timeout"
    assert f.get("https://a.org/down").error == "URLError: refused"


def test_redirect_loop_stops():
    s = fetcher(Site({"https://a.org/loop": redirect(301, "/loop")}), max_redirects=3).get("https://a.org/loop")
    assert s.error == "too-many-redirects"
    assert len(s.redirects) == 4


def test_large_bodies_are_cut():
    s = fetcher(Site({"https://a.org/big": Response(200, {}, b"x" * 5000)}), max_bytes=1000).get("https://a.org/big")
    assert (len(s.body), s.truncated) == (1000, True)


def test_rate_limit_waits_between_requests_to_one_host():
    site = Site({"https://a.org/1": Response(200), "https://a.org/2": Response(200)})
    ticks = iter([0.0, 0.0, 0.2, 0.2, 0.2, 0.2])
    slept: list[float] = []
    f = fetcher(site, clock=lambda: next(ticks), sleep=slept.append, min_interval=1.0)
    f.get("https://a.org/1")
    f.get("https://a.org/2")
    assert slept and all(0 < s <= 1.0 for s in slept)


# urllib_transport, with the module's opener replaced


class FakeResponse(io.BytesIO):
    def __init__(self, status, body=b"", headers=None):
        super().__init__(body)
        self.status = status
        self.headers = Message()
        for k, v in (headers or {}).items():
            self.headers[k] = v


class FakeOpener:
    def __init__(self, result):
        self.result = result
        self.requests = []

    def open(self, request, timeout):
        self.requests.append((request, timeout))
        if isinstance(self.result, BaseException):
            raise self.result
        return self.result


def transport(monkeypatch, result, max_bytes=100):
    opener = FakeOpener(result)
    monkeypatch.setattr(http, "_OPENER", opener)
    return http.urllib_transport("https://a.org/x", {"User-Agent": USER_AGENT}, 7.0, max_bytes), opener


def test_urllib_transport_reads_body_and_lower_cases_headers(monkeypatch):
    response, opener = transport(monkeypatch, FakeResponse(200, b"hello", {"Content-Type": "text/html"}))
    assert response == Response(200, {"content-type": "text/html"}, b"hello", False)
    request, timeout = opener.requests[0]
    assert (request.full_url, request.get_header("User-agent"), timeout) == ("https://a.org/x", USER_AGENT, 7.0)


def test_urllib_transport_returns_redirects_and_errors_as_responses(monkeypatch):
    headers = Message()
    headers["Location"] = "/y"
    error = urllib.error.HTTPError("https://a.org/x", 301, "Moved", headers, io.BytesIO(b""))
    response, _ = transport(monkeypatch, error)
    assert (response.status, response.headers["location"]) == (301, "/y")


def test_urllib_transport_caps_the_body(monkeypatch):
    response, _ = transport(monkeypatch, FakeResponse(200, b"x" * 500), max_bytes=100)
    assert (len(response.body), response.truncated) == (100, True)


@pytest.mark.parametrize(
    ("raised", "kind"),
    [
        (TimeoutError("timed out"), "timeout"),
        (urllib.error.URLError(TimeoutError("timed out")), "timeout"),
        (
            urllib.error.URLError("[Errno -2] Name or service not known"),
            "URLError: [Errno -2] Name or service not known",
        ),
        (ConnectionResetError("reset"), "ConnectionResetError: reset"),
    ],
)
def test_urllib_transport_maps_failures_to_fetch_errors(monkeypatch, raised, kind):
    with pytest.raises(FetchError) as info:
        transport(monkeypatch, raised)
    assert info.value.kind == kind


def test_no_redirect_handler_hands_redirects_back():
    assert http._NoRedirect().redirect_request(None, None, 301, "Moved", {}, "https://a.org/y") is None
