# SPDX-License-Identifier: Apache-2.0
"""HttpFetcher against httpx.MockTransport: no network."""

import httpx

from fdncheck.fetch.http import USER_AGENT, HttpFetcher

ROBOTS_OK = "User-agent: *\nDisallow: /private/\n"


def fetcher(handler, **kw):
    kw.setdefault("sleep", lambda s: None)
    return HttpFetcher(transport=httpx.MockTransport(handler), now=lambda: "2026-11-15T12:00:00Z", **kw)


def site(routes: dict, robots=(200, ROBOTS_OK)):
    seen: list[httpx.Request] = []

    def handler(request: httpx.Request) -> httpx.Response:
        seen.append(request)
        if request.url.path == "/robots.txt":
            return httpx.Response(robots[0], text=robots[1])
        route = routes.get(str(request.url))
        if route is None:
            return httpx.Response(404)
        if isinstance(route, Exception):
            raise route
        return route

    return handler, seen


def test_redirect_chain_is_recorded_with_relative_locations():
    handler, seen = site(
        {
            "http://a.org/x": httpx.Response(301, headers={"location": "https://a.org/x"}),
            "https://a.org/x": httpx.Response(308, headers={"location": "/y"}),
            "https://a.org/y": httpx.Response(200, html="<title>Y</title>", headers={"content-type": "text/html"}),
        }
    )
    s = fetcher(handler).get("http://a.org/x")
    assert s.redirects == ((301, "https://a.org/x"), (308, "https://a.org/y"))
    assert (s.final_url, s.status, s.error, s.fetched_at) == ("https://a.org/y", 200, None, "2026-11-15T12:00:00Z")
    assert s.body == b"<title>Y</title>"
    assert all(r.headers["user-agent"] == USER_AGENT for r in seen)


def test_robots_disallow_stops_the_fetch():
    handler, seen = site({"https://a.org/private/x": httpx.Response(200)})
    s = fetcher(handler).get("https://a.org/private/x")
    assert s.error == "robots-disallowed"
    assert [r.url.path for r in seen] == ["/robots.txt"]


def test_missing_robots_allows_and_is_fetched_once_per_origin():
    handler, seen = site(
        {"https://a.org/1": httpx.Response(200), "https://a.org/2": httpx.Response(200)}, robots=(404, "")
    )
    f = fetcher(handler)
    assert f.get("https://a.org/1").status == 200
    assert f.get("https://a.org/2").status == 200
    assert [r.url.path for r in seen] == ["/robots.txt", "/1", "/2"]


def test_robots_server_error_is_reported_not_disallowed():
    handler, _ = site({"https://a.org/": httpx.Response(200)}, robots=(500, ""))
    assert fetcher(handler).get("https://a.org/").error == "robots.txt answered HTTP 500"


def test_robots_can_be_ignored_for_testing():
    handler, seen = site({"https://a.org/private/x": httpx.Response(200)})
    assert fetcher(handler, obey_robots=False).get("https://a.org/private/x").status == 200
    assert [r.url.path for r in seen] == ["/private/x"]


def test_http_errors_are_data():
    handler, _ = site({"https://a.org/gone": httpx.Response(410)})
    s = fetcher(handler).get("https://a.org/gone")
    assert (s.status, s.error) == (410, None)


def test_timeout_and_connection_errors_become_snapshots():
    handler, _ = site(
        {
            "https://a.org/slow": httpx.ReadTimeout("slow"),
            "https://a.org/down": httpx.ConnectError("refused"),
        }
    )
    f = fetcher(handler)
    assert f.get("https://a.org/slow").error == "timeout"
    assert f.get("https://a.org/down").error == "ConnectError: refused"


def test_redirect_loop_stops():
    handler, _ = site({"https://a.org/loop": httpx.Response(301, headers={"location": "/loop"})})
    s = fetcher(handler, max_redirects=3).get("https://a.org/loop")
    assert s.error == "too-many-redirects"
    assert len(s.redirects) == 4


def test_large_bodies_are_cut():
    handler, _ = site({"https://a.org/big": httpx.Response(200, content=b"x" * 5000)})
    s = fetcher(handler, max_bytes=1000).get("https://a.org/big")
    assert (len(s.body), s.truncated) == (1000, True)


def test_rate_limit_waits_between_requests_to_one_host():
    handler, _ = site({"https://a.org/1": httpx.Response(200), "https://a.org/2": httpx.Response(200)})
    ticks = iter([0.0, 0.0, 0.2, 0.2, 0.2, 0.2])
    slept: list[float] = []
    f = fetcher(handler, clock=lambda: next(ticks), sleep=slept.append, min_interval=1.0)
    f.get("https://a.org/1")
    f.get("https://a.org/2")
    assert slept and all(0 < s <= 1.0 for s in slept)
