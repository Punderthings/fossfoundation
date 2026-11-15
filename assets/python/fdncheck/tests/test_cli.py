# SPDX-License-Identifier: Apache-2.0
"""The command line, run offline from saved Snapshots."""

from scenario import PAGES

from fdncheck.cli import main
from fdncheck.fetch.store import save


def saved(tmp_path):
    folder = tmp_path / "snaps"
    for page in PAGES.values():
        save(page, folder)
    return folder


def test_check_offline_prints_report_and_writes_nothing(repo, tmp_path, capsys):
    before = (repo / "_foundations" / "acme.md").read_text(encoding="utf-8")
    assert main(["--root", str(repo), "check", "acme", "--offline", str(saved(tmp_path))]) == 0
    out = capsys.readouterr().out
    assert out.startswith("## fdncheck(acme)")
    assert "Foundation: acme · Checked-by: fdncheck/0.1.0 · Checked-on: 2026-11-15" in out
    assert (repo / "_foundations" / "acme.md").read_text(encoding="utf-8") == before


def test_propose_shows_diff_then_writes(repo, tmp_path, capsys):
    snaps = saved(tmp_path)
    assert main(["--root", str(repo), "propose", "acme", "--offline", str(snaps)]) == 0
    out = capsys.readouterr().out
    assert "-website: http://acme.example.org/\n+website: https://acme.example.org/\n" in out
    msg = tmp_path / "msg.txt"
    assert (
        main(["--root", str(repo), "propose", "acme", "--offline", str(snaps), "--write", "--commit-message", str(msg)])
        == 0
    )
    assert "website: https://acme.example.org/\n" in (repo / "_foundations" / "acme.md").read_text(encoding="utf-8")
    assert msg.read_text(encoding="utf-8").startswith("fdncheck(acme): update")


def test_fields_lists_the_catalog(repo, capsys):
    assert main(["--root", str(repo), "fields"]) == 0
    assert "website\tA\tTrue\t1\t-" in capsys.readouterr().out


def test_validate_and_unknown_id(repo, capsys):
    assert main(["--root", str(repo), "validate"]) == 0
    assert main(["--root", str(repo), "check", "nosuch", "--offline", "x"]) == 2
    assert "no foundation record" in capsys.readouterr().err
