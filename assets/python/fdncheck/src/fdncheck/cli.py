# SPDX-License-Identifier: Apache-2.0
"""Command line for maintainers: list the field catalog, fetch a foundation's URLs, check it, propose edits.

fetch, check and propose take one foundation identifier. Every command works from the
repository root it finds above the current folder (or --root). Nothing is written unless --write, --save, --json,
--report or --commit-message is given.
"""

import argparse
import difflib
import sys
from pathlib import Path

from fdncheck import TOOL
from fdncheck.check import known_ids, run_check
from fdncheck.fetch import Fetcher
from fdncheck.fetch.http import HttpFetcher
from fdncheck.fetch.store import SavingFetcher, StoredFetcher
from fdncheck.propose import report
from fdncheck.records import foundation
from fdncheck.records.catalog import CATALOG
from fdncheck.records.schema import load_schema, uncovered_fields, validate


def find_root(start: Path) -> Path:
    for folder in (start, *start.parents):
        if (folder / "_foundations").is_dir() and (folder / "_data" / "foundations-schema.json").is_file():
            return folder
    raise SystemExit(f"fdncheck: no repository root (with _foundations/) above {start}; use --root")


def _fetcher(args: argparse.Namespace) -> Fetcher:
    if args.offline:
        return StoredFetcher(Path(args.offline))
    fetcher: Fetcher = HttpFetcher()
    if getattr(args, "save", None):
        fetcher = SavingFetcher(fetcher, Path(args.save))
    return fetcher


def cmd_fields(args: argparse.Namespace) -> int:
    schema = load_schema(args.root)
    print("field\tclass\tmay_update\tchecked_in_phase\tjoins")
    for name in schema.get("properties", {}):
        spec = CATALOG.get(name)
        if spec:
            print(f"{name}\t{spec.cls}\t{spec.may_update}\t{spec.checked_in_phase or '-'}\t{spec.joins or '-'}")
    for name in uncovered_fields(schema):
        print(f"{name}\t?\tnot in catalog", file=sys.stderr)
    return 1 if uncovered_fields(schema) else 0


def cmd_validate(args: argparse.Namespace) -> int:
    schema = load_schema(args.root)
    ids = args.ids or sorted(p.stem for p in (args.root / "_foundations").glob("*.md"))
    failed = 0
    for identifier in ids:
        problems = validate(foundation.load_id(args.root, identifier), schema)
        failed += bool(problems)
        for problem in problems:
            print(f"{identifier}: {problem}")
    print(f"fdncheck: {failed} of {len(ids)} records have schema problems", file=sys.stderr)
    return 1 if failed else 0


def cmd_fetch(args: argparse.Namespace) -> int:
    record = foundation.load_id(args.root, args.id)
    result = run_check(record, _fetcher(args), known_ids(args.root))
    for url, snap in result.snapshots.items():
        hops = "".join(f" {s}→{u}" for s, u in snap.redirects)
        print(f"{snap.status or snap.error}\t{url}{hops}")
    return 0


def _check(args: argparse.Namespace):
    record = foundation.load_id(args.root, args.id)
    result = run_check(record, _fetcher(args), known_ids(args.root))
    if args.json:
        Path(args.json).write_text(report.findings_json(args.id, result.findings), encoding="utf-8")
    text = report.markdown(args.id, result.findings, include_ok=getattr(args, "all", False))
    if args.report:
        Path(args.report).write_text(text, encoding="utf-8")
    return result, text


def cmd_check(args: argparse.Namespace) -> int:
    _result, text = _check(args)
    print(text, end="")
    return 0


def cmd_propose(args: argparse.Namespace) -> int:
    result, _text = _check(args)
    new_text = result.proposed_text()
    if args.commit_message and result.updates:
        Path(args.commit_message).write_text(report.commit_message(args.id, result.findings), encoding="utf-8")
    if new_text == result.record.text:
        print(f"fdncheck: no changes proposed for {args.id}", file=sys.stderr)
        return 0
    rel = result.record.path.relative_to(args.root)
    if args.write:
        result.record.path.write_text(new_text, encoding="utf-8")
        print(f"fdncheck: updated {rel}", file=sys.stderr)
    else:
        diff = difflib.unified_diff(
            result.record.text.splitlines(keepends=True), new_text.splitlines(keepends=True), f"a/{rel}", f"b/{rel}"
        )
        sys.stdout.writelines(diff)
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="fdncheck", description=__doc__)
    parser.add_argument("--version", action="version", version=TOOL)
    parser.add_argument("--root", type=Path, help="repository root (default: found above the current folder)")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("fields", help="print the field catalog: how each schema field is checked")

    def with_source(p: argparse.ArgumentParser) -> None:
        p.add_argument("id", help="foundation identifier, e.g. blender")
        group = p.add_mutually_exclusive_group()
        group.add_argument("--offline", metavar="DIR", help="replay Snapshots saved with --save instead of fetching")
        group.add_argument("--save", metavar="DIR", help="save every Snapshot fetched, for review or --offline")

    p = sub.add_parser("validate", help="check records against foundations-schema.json (blank values allowed)")
    p.add_argument("ids", nargs="*", help="foundation identifiers (default: all)")

    p = sub.add_parser("fetch", help="fetch a foundation's URLs and print each status and redirect")
    with_source(p)
    for name, help_text in (
        ("check", "print the review report for one foundation (read-only)"),
        ("propose", "as check, then print the proposed edit as a diff, or apply it with --write"),
    ):
        p = sub.add_parser(name, help=help_text)
        with_source(p)
        p.add_argument("--json", metavar="FILE", help="also write the findings as JSON")
        p.add_argument("--report", metavar="FILE", help="also write the Markdown report")
        p.add_argument("--all", action="store_true", help="list values that checked out fine too")
        if name == "propose":
            p.add_argument("--write", action="store_true", help="apply the edit to _foundations/<id>.md")
            p.add_argument("--commit-message", metavar="FILE", help="write a commit message with fdncheck trailers")
    return parser


COMMANDS = {
    "fields": cmd_fields,
    "validate": cmd_validate,
    "fetch": cmd_fetch,
    "check": cmd_check,
    "propose": cmd_propose,
}


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    args.root = (args.root or find_root(Path.cwd())).resolve()
    try:
        return COMMANDS[args.command](args)
    except foundation.RecordError as exc:
        print(f"fdncheck: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
