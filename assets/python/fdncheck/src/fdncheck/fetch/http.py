# SPDX-License-Identifier: Apache-2.0
"""Static HTTP fetching with the standard library: a recorded redirect chain, robots.txt, and a polite rate limit."""

import time
import urllib.error
import urllib.request
import urllib.robotparser
from collections.abc import Callable, Mapping
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Protocol, Self
from urllib.parse import urljoin, urlsplit

from fdncheck import TOOL
from fdncheck.fetch import Snapshot

USER_AGENT = f"{TOOL} (+https://fossfoundation.info/data#sourcing)"
REDIRECT_STATUSES = frozenset({301, 302, 303, 307, 308})


@dataclass(frozen=True)
class Response:
    """One HTTP response, before any redirect is followed. Header names are lower-case."""

    status: int
    headers: Mapping[str, str] = field(default_factory=dict)
    body: bytes = b""
    truncated: bool = False


class FetchError(Exception):
    """No response was received; ``kind`` is a short, stable label such as ``timeout``."""

    def __init__(self, kind: str) -> None:
        super().__init__(kind)
        self.kind = kind


class Transport(Protocol):
    """Sends one GET request without following redirects. Tests replace it; nothing else does."""

    def __call__(self, url: str, headers: Mapping[str, str], timeout: float, max_bytes: int) -> Response: ...


class _NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None  # hand every 3xx back to HttpFetcher, which records each hop


_OPENER = urllib.request.build_opener(_NoRedirect)


def urllib_transport(url: str, headers: Mapping[str, str], timeout: float, max_bytes: int) -> Response:
    """The real transport: ``urllib.request`` with redirects turned off and a size cap."""
    request = urllib.request.Request(url, headers=dict(headers), method="GET")
    try:
        response = _OPENER.open(request, timeout=timeout)
    except urllib.error.HTTPError as exc:  # 3xx, 4xx and 5xx arrive here; they are data, not errors
        response = exc
    except TimeoutError as exc:
        raise FetchError("timeout") from exc
    except urllib.error.URLError as exc:
        if isinstance(exc.reason, TimeoutError):
            raise FetchError("timeout") from exc
        raise FetchError(f"URLError: {exc.reason}") from exc
    except (OSError, ValueError) as exc:
        raise FetchError(f"{type(exc).__name__}: {exc}") from exc
    with response:
        try:
            body = response.read(max_bytes + 1) or b""
        except TimeoutError as exc:
            raise FetchError("timeout") from exc
        except OSError as exc:
            raise FetchError(f"{type(exc).__name__}: {exc}") from exc
        found = {k.lower(): v for k, v in response.headers.items()}
        return Response(response.status, found, body[:max_bytes], len(body) > max_bytes)


def _now() -> str:
    return datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ")


class HttpFetcher:
    """Fetch pages one at a time, following redirects by hand so each hop is recorded.

    Defaults are deliberately gentle: robots.txt is honored, each host gets at most one
    request per ``min_interval`` seconds, and bodies are cut at ``max_bytes``.
    ``transport``, ``clock``, ``sleep`` and ``now`` exist so tests never use the network.
    """

    def __init__(
        self,
        *,
        timeout: float = 30.0,
        max_redirects: int = 10,
        max_bytes: int = 5 * 1024 * 1024,
        min_interval: float = 1.0,
        obey_robots: bool = True,
        transport: Transport = urllib_transport,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
        now: Callable[[], str] = _now,
    ) -> None:
        self.timeout = timeout
        self.max_redirects = max_redirects
        self.max_bytes = max_bytes
        self.min_interval = min_interval
        self.obey_robots = obey_robots
        self._transport = transport
        self._clock = clock
        self._sleep = sleep
        self._now = now
        self._last: dict[str, float] = {}
        self._robots: dict[str, tuple[urllib.robotparser.RobotFileParser, str | None]] = {}

    def close(self) -> None:
        """Nothing to release: urllib opens one connection per request."""

    def __enter__(self) -> Self:
        return self

    def __exit__(self, *exc: object) -> None:
        self.close()

    def _wait(self, host: str) -> None:
        last = self._last.get(host)
        if last is not None:
            delay = self.min_interval - (self._clock() - last)
            if delay > 0:
                self._sleep(delay)
        self._last[host] = self._clock()

    def _send(self, url: str) -> Response:
        self._wait((urlsplit(url).hostname or "").lower())
        return self._transport(url, {"User-Agent": USER_AGENT}, self.timeout, self.max_bytes)

    def _robots_problem(self, url: str) -> str | None:
        """Apply robots.txt as RFC 9309 says; return why ``url`` may not be fetched, or None.

        A 4xx answer for robots.txt means everything is allowed. A 5xx answer or no answer
        means nothing is, and is reported as such rather than as a disallow rule.
        """
        if not self.obey_robots:
            return None
        parts = urlsplit(url)
        origin = f"{parts.scheme}://{parts.netloc}"
        if origin not in self._robots:
            parser = urllib.robotparser.RobotFileParser()
            problem = None
            try:
                response = self._send(origin + "/robots.txt")
                if response.status >= 500:
                    problem = f"robots.txt answered HTTP {response.status}"
                elif response.status >= 300:  # 4xx, or a redirect we don't follow for robots.txt
                    parser.allow_all = True
                else:
                    parser.parse(response.body.decode("utf-8", "replace").splitlines())
            except FetchError as exc:
                problem = f"robots.txt unreachable ({exc.kind})"
            self._robots[origin] = (parser, problem)
        parser, problem = self._robots[origin]
        if problem:
            return problem
        return None if parser.can_fetch(USER_AGENT, url) else "robots-disallowed"

    def get(self, url: str) -> Snapshot:
        fetched_at = self._now()
        redirects: list[tuple[int, str]] = []
        current = url
        for _ in range(self.max_redirects + 1):
            problem = self._robots_problem(current)
            if problem:
                return Snapshot(url, current, 0, fetched_at, tuple(redirects), error=problem)
            try:
                response = self._send(current)
            except FetchError as exc:
                return Snapshot(url, current, 0, fetched_at, tuple(redirects), error=exc.kind)
            location = response.headers.get("location")
            if response.status in REDIRECT_STATUSES and location:
                current = urljoin(current, location)
                redirects.append((response.status, current))
                continue
            return Snapshot(
                requested_url=url,
                final_url=current,
                status=response.status,
                fetched_at=fetched_at,
                redirects=tuple(redirects),
                content_type=response.headers.get("content-type", ""),
                body=response.body,
                truncated=response.truncated,
            )
        return Snapshot(url, current, 0, fetched_at, tuple(redirects), error="too-many-redirects")
