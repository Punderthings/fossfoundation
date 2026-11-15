# SPDX-License-Identifier: Apache-2.0
"""Save Snapshots to a folder and replay them, so a run can be reviewed and reproduced offline."""

import base64
import hashlib
import json
from pathlib import Path

from fdncheck.fetch import Fetcher, Snapshot


def _name(url: str) -> str:
    return hashlib.sha256(url.encode("utf-8")).hexdigest()[:24] + ".json"


def save(snapshot: Snapshot, folder: Path) -> Path:
    """Write one Snapshot as JSON, named after its requested URL."""
    folder.mkdir(parents=True, exist_ok=True)
    data = {
        "requested_url": snapshot.requested_url,
        "final_url": snapshot.final_url,
        "status": snapshot.status,
        "fetched_at": snapshot.fetched_at,
        "redirects": [list(hop) for hop in snapshot.redirects],
        "content_type": snapshot.content_type,
        "rendered": snapshot.rendered,
        "error": snapshot.error,
        "truncated": snapshot.truncated,
        "sha256": snapshot.sha256,
        "body_base64": base64.b64encode(snapshot.body).decode("ascii"),
    }
    path = folder / _name(snapshot.requested_url)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
    return path


def load(path: Path) -> Snapshot:
    data = json.loads(path.read_text(encoding="utf-8"))
    return Snapshot(
        requested_url=data["requested_url"],
        final_url=data["final_url"],
        status=data["status"],
        fetched_at=data["fetched_at"],
        redirects=tuple((int(s), str(u)) for s, u in data["redirects"]),
        content_type=data.get("content_type", ""),
        body=base64.b64decode(data.get("body_base64", "")),
        rendered=data.get("rendered", False),
        error=data.get("error"),
        truncated=data.get("truncated", False),
    )


class StoredFetcher:
    """Replays saved Snapshots; a URL that was never saved comes back as an error Snapshot."""

    def __init__(self, folder: Path) -> None:
        self.folder = folder

    def get(self, url: str) -> Snapshot:
        path = self.folder / _name(url)
        if not path.exists():
            return Snapshot(url, url, 0, "", error="not-in-snapshot-store")
        return load(path)


class SavingFetcher:
    """Wraps another Fetcher and saves every Snapshot it returns."""

    def __init__(self, inner: Fetcher, folder: Path) -> None:
        self.inner = inner
        self.folder = folder

    def get(self, url: str) -> Snapshot:
        snapshot = self.inner.get(url)
        save(snapshot, self.folder)
        return snapshot
