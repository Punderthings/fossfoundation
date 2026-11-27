#!/usr/bin/env python3
"""
Deterministic (no-AI) refresh detector for the FOSS Foundation leadership dataset.

For each _leadership/<id>.md record it fetches the foundation's leadership source
page, strips it to visible text, hashes that text, and compares the hash to the
last-seen hash in _data/leadership-refresh-state.json. It reports which
foundations' rosters have CHANGED, are NEW, or are UNREACHABLE, and writes the
set that needs re-extraction so a downstream step (an AI coding agent, or a
hand-written parser) only revisits pages that actually moved. A typical run flags
a handful of foundations, not all of them.

Pure Python standard library: runs on any python3 with no pip installs.

Usage:
  leadership_refresh.py                 # update state, print + optionally write changed set
  leadership_refresh.py --check         # dry run: report only, do not update state
  leadership_refresh.py --output changed.json
"""
import argparse
import hashlib
import json
import re
import ssl
import sys
import urllib.request
from datetime import date, datetime, timezone
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]          # repo root (assets/python/..)
LEADERSHIP_DIR = ROOT / "_leadership"
STATE_FILE = ROOT / "_data" / "leadership-refresh-state.json"
UA = "fossfoundation-leadership-refresh/1.0 (+https://fossfoundation.info)"
DISCOVERY_PATHS = [
    "/board", "/leadership", "/team", "/staff", "/people",
    "/governance", "/about", "/about-us", "/foundation",
]


class _Text(HTMLParser):
    """Collect visible text, dropping script/style/noscript content."""
    def __init__(self):
        super().__init__()
        self._skip = 0
        self.chunks = []

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style", "noscript"):
            self._skip += 1

    def handle_endtag(self, tag):
        if tag in ("script", "style", "noscript") and self._skip:
            self._skip -= 1

    def handle_data(self, data):
        if not self._skip:
            t = data.strip()
            if t:
                self.chunks.append(t)


def visible_text(html):
    p = _Text()
    try:
        p.feed(html)
    except Exception:
        pass
    return re.sub(r"\s+", " ", " ".join(p.chunks)).strip()


def fetch(url, timeout=20):
    ctx = ssl.create_default_context()
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout, context=ctx) as r:
        raw = r.read()
        enc = r.headers.get_content_charset() or "utf-8"
    return raw.decode(enc, "replace")


def frontmatter(md_text):
    """Pull identifier + all url:/sourceUrl: values from the YAML frontmatter block."""
    m = re.search(r"^---\s*\n(.*?)\n---\s*\n", md_text, re.S)
    fm = m.group(1) if m else md_text
    ident = None
    mid = re.search(r"^identifier:\s*(\S+)", fm, re.M)
    if mid:
        ident = mid.group(1).strip().strip("'\"")
    urls = []
    for mu in re.finditer(r"(?:sourceUrl|url):\s*(https?://\S+)", fm):
        u = mu.group(1).strip().strip("'\",")
        if u not in urls:
            urls.append(u)
    return ident, urls


def norm_hash(text):
    return hashlib.sha256(text.encode("utf-8", "replace")).hexdigest()


def domain_root(url):
    m = re.match(r"(https?://[^/]+)", url)
    return m.group(1) if m else url


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="dry run; do not write state")
    ap.add_argument("--output", default=None, help="write changed-set JSON here")
    args = ap.parse_args()

    if not LEADERSHIP_DIR.is_dir():
        print(f"No _leadership dir at {LEADERSHIP_DIR}", file=sys.stderr)
        return 1

    state = {}
    if STATE_FILE.exists():
        try:
            state = json.loads(STATE_FILE.read_text())
        except Exception:
            state = {}

    changed, new, unreachable, unchanged = [], [], [], []
    now = datetime.now(timezone.utc).isoformat()
    new_state = {}
    records = sorted(LEADERSHIP_DIR.glob("*.md"))

    for md in records:
        ident, urls = frontmatter(md.read_text(encoding="utf-8", errors="replace"))
        ident = ident or md.stem
        if not urls:
            unreachable.append((ident, "no source url in record"))
            new_state[ident] = state.get(ident, {})
            continue
        primary = urls[0]
        candidates = [primary] + [domain_root(primary) + p for p in DISCOVERY_PATHS]
        text, used = None, None
        for cand in candidates:
            try:
                text = visible_text(fetch(cand))
                used = cand
                break
            except Exception:
                continue
        if not text:
            unreachable.append((ident, primary))
            new_state[ident] = state.get(ident, {})
            continue
        h = norm_hash(text)
        prev = state.get(ident, {}).get("hash")
        new_state[ident] = {"url": used, "hash": h, "checked": now}
        if prev is None:
            new.append(ident)
        elif prev != h:
            changed.append(ident)
        else:
            unchanged.append(ident)

    to_reextract = sorted(set(changed) | set(new))
    print(f"Leadership refresh check ({date.today().isoformat()})")
    print(f"  records:     {len(records)}")
    print(f"  changed:     {len(changed)}  {sorted(changed)}")
    print(f"  new:         {len(new)}  {sorted(new)}")
    print(f"  unchanged:   {len(unchanged)}")
    print(f"  unreachable: {len(unreachable)}  {[u[0] for u in unreachable]}")
    print(f"  -> re-extract {len(to_reextract)} of {len(records)} foundations")

    if args.output:
        Path(args.output).write_text(json.dumps(to_reextract, indent=2))
    if not args.check:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        STATE_FILE.write_text(json.dumps(new_state, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
