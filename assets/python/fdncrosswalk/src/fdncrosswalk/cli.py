"""Command line: validate crosswalk files, report confidence, print ecosyste.ms lookups, probe registries,
write the public exports, sync the project CSVs, add attestation person records, and add or renew
human-attested evidence."""

import argparse
import json
import sys
from dataclasses import asdict
from datetime import date
from pathlib import Path

from fdncrosswalk import attest, export, probes
from fdncrosswalk.crosswalk import PENDING_SOURCE, assess, load_attestors, load_dir, validate
from fdncrosswalk.ecosystems import MAILTO, MAILTO_ENV, lookup_urls, package_lookup_urls

REPO_ROOT = Path(__file__).resolve().parents[5]
DEFAULT_DIR = REPO_ROOT / "_data" / "crosswalk"
DEFAULT_SCHEMA = REPO_ROOT / "_data" / "crosswalk-schema.json"
DEFAULT_ATTESTORS = REPO_ROOT / "_data" / "attestors.json"
ATTESTORS_SCHEMA = REPO_ROOT / "_data" / "attestors-schema.json"
FOUNDATIONS_DIR = REPO_ROOT / "_foundations"
ENTITIES_DIR = REPO_ROOT / "_entities"
PUBLIC_ATTESTATIONS = REPO_ROOT / "_data" / "attestations.json"
ATTESTATIONS_SCHEMA = REPO_ROOT / "_data" / "attestations-schema.json"
PRIVATE_ATTESTATIONS = REPO_ROOT.parent / "fossfoundation-private" / "attestations.json"
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
    schema = json.loads(ATTESTATIONS_SCHEMA.read_text(encoding="utf-8"))
    people = attest.read_records(PUBLIC_ATTESTATIONS)
    errors = validate(people, schema)
    if errors:
        raise ValueError(f"{PUBLIC_ATTESTATIONS}: " + "; ".join(errors))
    if any(p["visibility"] != "public" for p in people["attestations"]):
        raise ValueError(f"{PUBLIC_ATTESTATIONS}: only public records belong in this repository")
    known = {p.stem for p in (*FOUNDATIONS_DIR.glob("*.md"), *ENTITIES_DIR.glob("*.md"))}
    for attestor in json.loads(Path(args.attestors).read_text(encoding="utf-8"))["attestors"]:
        org = attestor.get("memberOf")
        if org and not org.startswith(("https://", "http://")) and org not in known:
            raise ValueError(f"{args.attestors}: {attestor['login']}: memberOf {org!r} is not a _foundations or "
                             "_entities identifier, or a website URL")
    print(f"{len(crosswalks)} crosswalk files valid; {len(attestors)} attestors; {len(people['attestations'])} public people")
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
    documents = _documents(args)
    renewals = attest.due(documents, today)
    pending = [
        (data["identifier"], label, item)
        for data in documents
        for label, entry in attest.targets(data).items()
        for item in entry["evidence"]
        if item["source"] == PENDING_SOURCE
    ]
    if renewals or pending:
        print("# human attestations to renew or finish, by attestor")
        rows = [(d.evidence.get("creator", ""), "stale" if d.stale else "renew", d.foundation, d.target,
                 f"expires {d.expires.isoformat()}") for d in renewals]
        rows += [(item.get("creator", ""), "source pending", fdn, label, f"observed {item['observed']}")
                 for fdn, label, item in pending]
        for row in sorted(rows):
            print("\t".join(row))
    return 0


def _documents(args: argparse.Namespace) -> list[dict]:
    """The raw crosswalk documents, validated, for tools that edit them."""
    _load(args)
    return [json.loads(p.read_text(encoding="utf-8")) for p in sorted(Path(args.dir).glob("*.json"))]


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


def _inside(path: Path, root: Path) -> bool:
    return path.resolve().is_relative_to(root.resolve())


def cmd_add_person(args: argparse.Namespace) -> int:
    record = _add_person(args, input, print)
    if record is None:
        return 1
    print("In the crosswalk evidence (type human-attested), use this confirmedWith, which holds no email:")
    print(json.dumps(attest.confirmed_with(record), indent=2))
    return 0


def _add_person(args: argparse.Namespace, ask, say) -> dict | None:
    """Interview, confirm and save a person record; return it, or None if not saved."""
    schema = json.loads(ATTESTATIONS_SCHEMA.read_text(encoding="utf-8"))
    record = attest.interview(
        ask,
        say,
        schema=schema,
        foundations=(p.stem for p in FOUNDATIONS_DIR.glob("*.md")),
        attestors=_attestors(args),
        today=_today(args),
        visibility=args.visibility,
        test=args.test,
    )
    if record["visibility"] == "public":
        path = Path(args.public_file)
    else:
        path = Path(args.private_file)
        if _inside(path, REPO_ROOT):
            raise ValueError(f"{path} is inside the public repository; private records must not be stored here")
        if not path.parent.is_dir():
            raise ValueError(f"{path.parent} not found; clone the private repository there or pass --private-file")
    say(json.dumps(record, indent=2, ensure_ascii=False))
    if not attest.yes(ask, say, f"Save this record to {path}?", True):
        say("Not saved.")
        return None
    attest.add_record(path, record, schema)
    say(f"Saved. Commit {path.name} on a branch in that repository and open a pull request.")
    return record


def _people(args: argparse.Namespace) -> dict[str, dict]:
    """Person records available here: the public file, plus the private one if a maintainer has it."""
    records = {}
    for path in (Path(args.public_file), Path(args.private_file)):
        records.update({r["identifier"]: r for r in attest.read_records(path)["attestations"]})
    return records


def _finish(args: argparse.Namespace, changed: list[Path]) -> None:
    for path in changed:
        print(f"updated {path}")
    if not args.no_export:
        cmd_export(argparse.Namespace(**{**vars(args), "out": str(DEFAULT_EXPORT_DIR)}))
    print("Commit the crosswalk files and exports together and open a pull request. Then replace any "
          f"source {PENDING_SOURCE!r} with that pull request's URL, or leave it for a maintainer.")


def cmd_attest(args: argparse.Namespace) -> int:
    ask, say = input, print
    schema = json.loads(Path(args.schema).read_text(encoding="utf-8"))
    methods = attest.evidence_methods(schema)
    if args.renew:
        documents = _documents(args)
        if args.foundation:
            documents = [d for d in documents if d["identifier"] == args.foundation]
        if not args.creator:
            raise ValueError("--renew needs --creator, your GitHub login")
        creator = args.creator
        items = attest.due(documents, _today(args), creator)
        if not items:
            say(f"No attestations by {creator} are stale or due within {attest.RENEW_WINDOW.days} days.")
            return 0
        renewed = attest.renew(ask, say, items, methods=methods, today=_today(args))
        changed = sorted({Path(args.dir) / f"{d.foundation}.json" for d in renewed})
        by_id = {d["identifier"]: d for d in documents}
        for path in changed:
            attest.save_crosswalk(path, by_id[path.stem], schema)
        _finish(args, changed)
        return 0
    if not args.foundation:
        raise ValueError("name the foundation whose crosswalk to add evidence to, or use --renew")
    path = Path(args.dir) / f"{args.foundation}.json"
    if not path.exists():
        raise ValueError(f"{path} not found; crosswalk files are named by foundation identifier")
    _load(args)
    data = json.loads(path.read_text(encoding="utf-8"))

    def new_person() -> dict:
        record = _add_person(args, ask, say)
        if record is None:
            raise ValueError("no person record saved, so no evidence was added")
        return record

    target, item = attest.evidence_interview(
        ask, say, data=data, methods=methods, attestors=_attestors(args), people=_people(args),
        new_person=new_person, today=_today(args), target=args.target, creator=args.creator,
    )
    say(json.dumps(item, indent=2, ensure_ascii=False))
    if not attest.yes(ask, say, f"Add this evidence to {target} in {path}?", True):
        say("Not saved.")
        return 1
    attest.targets(data)[target]["evidence"].append(item)
    attest.save_crosswalk(path, data, schema)
    _finish(args, [path])
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
    person = sub.add_parser("add-person", help="ask questions and add a person record for human-attested evidence")
    person.add_argument("--visibility", choices=["public", "private"], help="skip the public or private question")
    person.add_argument("--public-file", default=str(PUBLIC_ATTESTATIONS), help="public attestations file")
    person.add_argument(
        "--private-file", default=str(PRIVATE_ATTESTATIONS), help="attestations file in the private repository clone"
    )
    person.add_argument("--test", action="store_true", help="make a test record with the all-zeros identifier")
    person.set_defaults(func=cmd_add_person)
    att = sub.add_parser("attest", help="ask questions and add human-attested evidence, or renew it with --renew")
    att.add_argument("foundation", nargs="?", help="crosswalk to add evidence to (a foundation identifier)")
    att.add_argument("--target", help="account as <platform>/<name>, or package purl; asked if left out")
    att.add_argument("--creator", help="your GitHub login, as listed in _data/attestors.json")
    att.add_argument("--renew", action="store_true", help="re-confirm your attestations that are stale or due soon")
    att.add_argument("--no-export", action="store_true", help="skip regenerating the exports")
    att.add_argument("--visibility", choices=["public", "private"], help="for a new person record")
    att.add_argument("--public-file", default=str(PUBLIC_ATTESTATIONS), help="public attestations file")
    att.add_argument(
        "--private-file", default=str(PRIVATE_ATTESTATIONS), help="attestations file in the private repository clone"
    )
    att.add_argument("--test", action="store_true", help="make any new person record a test record")
    att.set_defaults(func=cmd_attest)
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except ValueError as err:
        print(err, file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
