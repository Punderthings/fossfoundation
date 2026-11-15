# SPDX-License-Identifier: Apache-2.0
"""The review text: Markdown for a PR or summary issue, JSON findings, and the commit message.

Everything here is built from fixed templates, so the same findings always give the same
text. Every output names the foundation the same way, so its history is easy to search:
``fdncheck(<id>)`` in titles and commit subjects, and ``Foundation: <id>`` trailers.
"""

import json

from fdncheck import TOOL
from fdncheck.detect import Finding


def checked_on(findings: list[Finding]) -> str:
    """The latest fetch date among the findings, so a replay gives the same date."""
    dates = [f.snapshot.checked_on for f in findings if f.snapshot and f.snapshot.fetched_at]
    return max(dates) if dates else ""


def tag_line(identifier: str, date: str) -> str:
    return f"Foundation: {identifier} · Checked-by: {TOOL} · Checked-on: {date}"


def _status(finding: Finding) -> str:
    snap = finding.snapshot
    if snap is None:
        return ""
    if snap.redirects:
        return f" ({' → '.join(str(s) for s, _ in snap.redirects)} → {snap.status or snap.error})"
    return f" ({snap.status})" if snap.status else ""


def _cell(value: object) -> str:
    return str(value).replace("|", "\\|")


def markdown(identifier: str, findings: list[Finding], *, include_ok: bool = False) -> str:
    updates = [f for f in findings if f.action == "update"]
    flags = [f for f in findings if f.action == "flag"]
    unchecked = [f for f in findings if f.action == "unchecked"]
    ok = [f for f in findings if f.action == "ok"]
    urls = {f.snapshot.requested_url for f in findings if f.snapshot}
    date = checked_on(findings)
    out = [
        f"## fdncheck({identifier})",
        "",
        (
            f"{TOOL} checked {len(urls)} URLs for `{identifier}`{f' on {date} (UTC)' if date else ''}: "
            f"{len(updates)} to change, {len(flags)} to check, {len(unchecked)} could not be checked, {len(ok)} fine."
        ),
        "",
    ]
    if updates:
        out += ["### Changes (verified by rule)", "", "| Field | Was | Now | Rule |", "| --- | --- | --- | --- |"]
        out += [f"| `{f.field}` | {_cell(f.current)} | {_cell(f.proposed)} | `{f.rule}`{_status(f)} |" for f in updates]
        out.append("")
    if flags:
        out += ["### Please check (not changed)", ""]
        out += [f"- `{f.field}` {_cell(f.current)}: {f.reason}{_status(f)} `{f.rule}`" for f in flags]
        out.append("")
    if unchecked:
        out += ["### Could not check", ""]
        out += [f"- `{f.field}` {_cell(f.current)}: {f.reason} `{f.rule}`" for f in unchecked]
        out.append("")
    if include_ok and ok:
        out += ["### Fine", ""]
        out += [f"- `{f.field}` {_cell(f.current)}: {f.reason}" for f in ok]
        out.append("")
    out += [tag_line(identifier, date), ""]
    return "\n".join(out)


def findings_json(identifier: str, findings: list[Finding]) -> str:
    def one(f: Finding) -> dict:
        snap = f.snapshot
        return {
            "key": f.key,
            "field": f.field,
            "current": f.current,
            "action": f.action,
            "rule": f.rule,
            "reason": f.reason,
            "proposed": f.proposed,
            "source": None
            if snap is None
            else {
                "requested_url": snap.requested_url,
                "final_url": snap.final_url,
                "status": snap.status,
                "redirects": [list(h) for h in snap.redirects],
                "fetched_at": snap.fetched_at,
                "error": snap.error,
                "sha256": snap.sha256,
            },
        }

    doc = {
        "identifier": identifier,
        "tool": TOOL,
        "checkedOn": checked_on(findings),
        "findings": [one(f) for f in findings],
    }
    return json.dumps(doc, indent=2, ensure_ascii=False, default=str) + "\n"


def commit_message(identifier: str, findings: list[Finding]) -> str:
    """Subject, body and trailers for a commit that applies this run's updates."""
    updates = [f for f in findings if f.action == "update"]
    fields = sorted({f.field for f in updates})
    lines = [f"fdncheck({identifier}): update {', '.join(fields)}", ""]
    lines += [f"- {f.field}: {f.current} -> {f.proposed} ({f.rule})" for f in updates]
    lines += [
        "",
        f"Foundation: {identifier}",
        f"Checked-by: {TOOL}",
        f"Checked-on: {checked_on(findings)}",
        "",
    ]
    return "\n".join(lines)
