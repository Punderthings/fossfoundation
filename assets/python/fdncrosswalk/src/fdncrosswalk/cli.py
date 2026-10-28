"""Command line: validate crosswalk files, report confidence, print ecosyste.ms lookups, probe registries,
write the public exports and sync the project CSVs."""

import argparse
import json
import sys
from dataclasses import asdict
from datetime import date
from pathlib import Path

from fdncrosswalk import export, probes
from fdncrosswalk.crosswalk import assess, load_attestors, load_dir
from fdncrosswalk.ecosystems import MAILTO, MAILTO_ENV, lookup_urls, package_lookup_urls

REPO_ROOT = Path(__file__).resolve().parents[5]
DEFAULT_DIR = REPO_ROOT / "_data" / "crosswalk"
DEFAULT_SCHEMA = REPO_ROOT / "_data" / "crosswalk-schema.json"
DEFAULT_ATTESTORS = REPO_ROOT / "_data" / "attestors.json"
ATTESTORS_SCHEMA = REPO_ROOT / "_data" / "attestors-schema.json"
FOUNDATIONS_DIR = REPO_ROOT / "_foundations"
DEFAULT_EXPORT_DIR = REPO_ROOT / export.EXPORT_PATH


def _load(args: argparse.Namespace):
    schema = json.loads(Path(args.schema).read_text(encoding="utf-8"))
    return load_dir(Path(args.dir), schema)


def _attestors(args: argparse.Namespace) -> frozenset[str]:
    schema = json.loads(ATTESTORS_SCHEMA.read_text(encoding="utf-8"))
    return load_attestors(Path(args.attestors), schema)


def _today(args: argparse.Namespace) -> date:
    return date.fromisoformat(args.today) if args.today else date.today()


def cmd_validate(args: argparse.Namespace) -> int:
    crosswalks = _load(args)
    attestors = _attestors(args)
    print(f"{len(crosswalks)} crosswalk files valid; {len(attestors)} attestors")
    return 0


def _level(result) -> str:
    return f"{result.confidence} (stale)" if result.stale else result.confidence


def cmd_report(args: argparse.Namespace) -> int:
    attestors, today = _attestors(args), _today(args)
    for cw in _load(args):
        for account in cw.accounts:
            where = account.host or account.platform
            project = f" [{account.project}]" if account.project else ""
            level = _level(assess(account, attestors, today))
            print(f"{cw.identifier}\t{level}\t{where}\t{account.kind}\t{account.name}{project}")
        for package in cw.packages:
            project = f" [{package.project}]" if package.project else ""
            level = _level(assess(package, attestors, today))
            print(f"{cw.identifier}\t{level}\tpackage\t{package.purl}{project}")
    return 0


def cmd_urls(args: argparse.Namespace) -> int:
    if not args.mailto:
        print(f"warning: set {MAILTO_ENV} or --mailto to use the ecosyste.ms polite pool", file=sys.stderr)
    attestors = _attestors(args)
    for cw in _load(args):
        for account in cw.accounts:
            if assess(account, attestors).confidence == "rejected":
                continue
            for index, url in lookup_urls(account, args.mailto).items():
                print(f"{cw.identifier}\t{account.platform}\t{account.name}\t{index}\t{url}")
        for package in cw.packages:
            if assess(package, attestors).confidence == "rejected":
                continue
            for index, url in package_lookup_urls(package, args.mailto).items():
                print(f"{cw.identifier}\tpackage\t{package.purl}\t{index}\t{url}")
    return 0


def cmd_export(args: argparse.Namespace) -> int:
    written = export.write_exports(_load(args), Path(args.out), FOUNDATIONS_DIR, _attestors(args), _today(args))
    print(f"wrote {len(written)} files to {args.out}")
    return 0


def cmd_sync_csv(args: argparse.Namespace) -> int:
    attestors = _attestors(args)
    for cw in _load(args):
        path = Path(args.data) / f"projects-{cw.identifier}.csv"
        columns = export.project_columns(cw, attestors)
        if not path.exists() or not columns:
            continue
        old = path.read_text(encoding="utf-8")
        new = export.sync_csv(old, columns)
        if new != old:
            path.write_text(new, encoding="utf-8")
            print(f"updated {path}")
    return 0


def cmd_probe(args: argparse.Namespace) -> int:
    if args.platform == "hub.docker.com":
        found = probes.docker_hub_org(args.name)
    elif args.platform == "pypi.org":
        found = probes.pypi_provenance(args.name)
    else:
        packages = probes.npm_org_packages(args.name)
        print(json.dumps({"scope": args.name, "packages": packages}, indent=2))
        return 0
    print(json.dumps([asdict(e) for e in found], indent=2))
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="fdncrosswalk", description=__doc__)
    parser.add_argument("--dir", default=str(DEFAULT_DIR), help="crosswalk directory")
    parser.add_argument("--schema", default=str(DEFAULT_SCHEMA), help="crosswalk JSON schema")
    parser.add_argument("--attestors", default=str(DEFAULT_ATTESTORS), help="attestors file")
    parser.add_argument("--today", help="date to judge staleness against (YYYY-MM-DD); default today")
    sub = parser.add_subparsers(dest="command", required=True)
    sub.add_parser("validate", help="check every crosswalk file against the schema").set_defaults(func=cmd_validate)
    sub.add_parser("report", help="list accounts and packages with computed confidence").set_defaults(func=cmd_report)
    urls = sub.add_parser("urls", help="print ecosyste.ms lookup URLs for non-rejected accounts and packages")
    urls.add_argument("--mailto", default=MAILTO, help=f"contact email for ecosyste.ms; default ${MAILTO_ENV}")
    urls.set_defaults(func=cmd_urls)
    probe = sub.add_parser("probe", help="suggest evidence from a registry's public API")
    probe.add_argument("platform", choices=["hub.docker.com", "pypi.org", "npmjs.org"])
    probe.add_argument("name", help="Docker Hub org, PyPI project, or npm scope")
    probe.set_defaults(func=cmd_probe)
    exp = sub.add_parser("export", help="write per-foundation JSON-LD, context, vocabulary and stewards.jsonl")
    exp.add_argument("--out", default=str(DEFAULT_EXPORT_DIR))
    exp.set_defaults(func=cmd_export)
    sync = sub.add_parser("sync-csv", help="fill purl and codeRepository columns in _data/projects-*.csv")
    sync.add_argument("--data", default=str(REPO_ROOT / "_data"))
    sync.set_defaults(func=cmd_sync_csv)
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ValueError as err:
        print(err, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
