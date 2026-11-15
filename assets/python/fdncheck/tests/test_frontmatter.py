# SPDX-License-Identifier: Apache-2.0
import pytest
from conftest import FIXTURES, REPO_ROOT

from fdncheck.propose.frontmatter import EditError, apply, replace_value
from fdncheck.records import foundation
from fdncheck.records.catalog import url_targets

TEXT = (FIXTURES / "acme-foundation.txt").read_text(encoding="utf-8")


def changed_lines(before: str, after: str) -> list[tuple[str, str]]:
    return [(a, b) for a, b in zip(before.splitlines(), after.splitlines(), strict=True) if a != b]


def test_scalar_value_changes_only_its_line():
    after = replace_value(TEXT, "website", "http://acme.example.org/", "https://acme.example.org/")
    assert changed_lines(TEXT, after) == [("website: http://acme.example.org/", "website: https://acme.example.org/")]


def test_list_items_keep_indent_and_quotes():
    after = apply(
        TEXT,
        [
            ("conductProjects", "https://acme.example.org/old-coc", "https://acme.example.org/new-coc"),
            ("conductProjects", "https://acme.example.org/project-coc", "https://acme.example.org/p'coc"),
        ],
    )
    assert changed_lines(TEXT, after) == [
        ("- https://acme.example.org/old-coc", "- https://acme.example.org/new-coc"),
        ("- 'https://acme.example.org/project-coc'", "- 'https://acme.example.org/p''coc'"),
    ]
    assert foundation.parse(after, FIXTURES)["conductProjects"][1] == "https://acme.example.org/p'coc"


def test_quoted_scalars_stay_quoted():
    after = replace_value(TEXT, "foundingDate", "2001", "2002")
    assert changed_lines(TEXT, after) == [("foundingDate: '2001'", "foundingDate: '2002'")]


def test_wrong_old_value_or_missing_field_is_an_error():
    with pytest.raises(EditError):
        replace_value(TEXT, "website", "https://other.example/", "https://x.example/")
    with pytest.raises(EditError):
        replace_value(TEXT, "logo", "a", "b")
    with pytest.raises(EditError):
        replace_value(TEXT, "conductProjects", "https://not-there.example/", "b")


def test_body_text_is_never_edited():
    text = TEXT + "Visit http://acme.example.org/ today.\n"
    after = replace_value(text, "website", "http://acme.example.org/", "https://acme.example.org/")
    assert after.endswith("Visit http://acme.example.org/ today.\n")


@pytest.mark.parametrize("path", sorted((REPO_ROOT / "_foundations").glob("*.md")), ids=lambda p: p.stem)
def test_real_records_round_trip_byte_for_byte(path):
    """Replacing every URL with itself leaves every real record unchanged."""
    record = foundation.load(path)
    targets = url_targets(record.data)
    assert targets or record.identifier == "biobricks"
    assert apply(record.text, [(f, u, u) for f, u in targets]) == record.text
