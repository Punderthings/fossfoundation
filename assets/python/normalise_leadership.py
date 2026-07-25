#!/usr/bin/env python3
"""
Normalise crawl-output leadership records (snake_case fields) into the published
_leadership schema (camelCase, per _data/leadership-schema.json). Reads a source
directory of <slug>.md files, remaps keys, and re-emits YAML frontmatter with the
Markdown body preserved, into the destination collection. Idempotent and
repeatable: re-run whenever the crawl adds more files.

Usage:
  normalise_leadership.py --src <crawl_dir> --dst <repo>/_leadership

Requires PyYAML (run with the toolbox python3, or `pip install pyyaml`).
"""
import argparse
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    sys.exit("PyYAML required: run with toolbox python3 or `pip install pyyaml`")

TOP = {"foundation": "identifier", "foundation_name": "commonName", "as_of": "asOf"}
PERSON = {
    "person_id": "personId",
    "role_class": "roleClass",
    "term_start": "termStart",
    "term_end": "termEnd",
    "source_url": "sourceUrl",
}
ORDER = ["identifier", "commonName", "asOf", "sources", "people"]


def split_frontmatter(md):
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n?(.*)$", md, re.S)
    if not m:
        return None, md
    return m.group(1), m.group(2)


def remap(d, mapping):
    return {mapping.get(k, k): v for k, v in d.items()} if isinstance(d, dict) else d


def norm_person(p):
    if not isinstance(p, dict):
        return p
    p = remap(p, PERSON)
    p["roles"] = [remap(r, PERSON) for r in (p.get("roles") or [])]
    return p


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True, help="crawl output dir of <slug>.md files")
    ap.add_argument("--dst", required=True, help="destination _leadership collection")
    a = ap.parse_args()
    src, dst = Path(a.src), Path(a.dst)
    if not src.is_dir():
        sys.exit(f"src not found: {src}")
    dst.mkdir(parents=True, exist_ok=True)

    n = empty = skipped = 0
    for md in sorted(src.glob("*.md")):
        fm_raw, body = split_frontmatter(md.read_text(encoding="utf-8", errors="replace"))
        if fm_raw is None:
            print(f"skip (no frontmatter): {md.name}")
            skipped += 1
            continue
        try:
            fm = yaml.safe_load(fm_raw) or {}
        except Exception as e:
            print(f"skip (bad yaml): {md.name}: {e}")
            skipped += 1
            continue
        fm = remap(fm, TOP)
        fm["people"] = [norm_person(p) for p in (fm.get("people") or [])]
        if not fm["people"]:
            empty += 1
        ident = fm.get("identifier") or md.stem
        ordered = {k: fm[k] for k in ORDER if k in fm}
        for k in fm:
            if k not in ordered:
                ordered[k] = fm[k]
        yaml_out = yaml.safe_dump(
            ordered, sort_keys=False, allow_unicode=True,
            default_flow_style=False, width=100,
        ).rstrip()
        out = f"---\n{yaml_out}\n---\n\n{body.strip()}\n"
        (dst / f"{ident}.md").write_text(out, encoding="utf-8")
        n += 1

    print(f"normalised {n} files -> {dst}  (empty rosters: {empty}, skipped: {skipped})")


if __name__ == "__main__":
    sys.exit(main())
