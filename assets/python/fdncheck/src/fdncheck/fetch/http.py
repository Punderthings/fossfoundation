# SPDX-License-Identifier: Apache-2.0
"""Static HTTP fetching with a recorded redirect chain, robots.txt, and a polite rate limit."""

import time
import urllib.robotparser
from collections.abc import Callable
from datetime import UTC, datetime
from typing import Self
from urllib.parse import urljoin, urlsplit

import httpx

from fdncheck import TOOL
from fdncheck.fetch import Snapshot

USER_AGENT = f"{TOOL} (+https://fossfoundation.info/data#sourcing)"
REDIRECT_STATUSES = frozenset({301, 302, 303, 307, 308})


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
        transport: httpx.BaseTransport | None = None,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
        now: Callable[[], str] = _now,
    ) -> None:
        self.max_redirects = max_redirects
        self.max_bytes = max_bytes
        self.min_interval = min_interval
        self.obey_robots = obey_robots
        self._clock = clock
        self._sleep = sleep
        self._now = now
        self._last: dict[str, float] = {}
        self._robots: dict[str, tuple[urllib.robotparser.RobotFileParser, str | None]] = {}
        self._client = httpx.Client(
            timeout=timeout,
            follow_redirects=False,
            headers={"User-Agent": USER_AGENT},
            transport=transport,
        )

    def close(self) -> None:
        self._client.close()

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
                self._wait(parts.netloc.lower())
                response = self._client.get(origin + "/robots.txt")
                if response.status_code >= 500:
                    problem = f"robots.txt answered HTTP {response.status_code}"
                elif response.status_code >= 400:
                    parser.allow_all = True
                else:
                    parser.parse(response.text.splitlines())
            except httpx.HTTPError as exc:
                problem = f"robots.txt unreachable ({type(exc).__name__}: {exc})"
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
                self._wait(urlsplit(current).netloc.lower())
                with self._client.stream("GET", current) as response:
                    status = response.status_code
                    location = response.headers.get("location")
                    if status in REDIRECT_STATUSES and location:
                        target = urljoin(current, location)
                        redirects.append((status, target))
                        current = target
                        continue
                    body, truncated = self._read(response)
                    return Snapshot(
                        requested_url=url,
                        final_url=current,
                        status=status,
                        fetched_at=fetched_at,
                        redirects=tuple(redirects),
                        content_type=response.headers.get("content-type", ""),
                        body=body,
                        truncated=truncated,
                    )
            except httpx.TimeoutException:
                return Snapshot(url, current, 0, fetched_at, tuple(redirects), error="timeout")
            except httpx.HTTPError as exc:
                return Snapshot(url, current, 0, fetched_at, tuple(redirects), error=f"{type(exc).__name__}: {exc}")
        return Snapshot(url, current, 0, fetched_at, tuple(redirects), error="too-many-redirects")

    def _read(self, response: httpx.Response) -> tuple[bytes, bool]:
        chunks: list[bytes] = []
        size = 0
        for chunk in response.iter_bytes():
            chunks.append(chunk)
            size += len(chunk)
            if size > self.max_bytes:
                return b"".join(chunks)[: self.max_bytes], True
        return b"".join(chunks), False
