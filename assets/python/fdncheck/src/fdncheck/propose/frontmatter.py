# SPDX-License-Identifier: Apache-2.0
"""Change values in YAML front matter by editing only the lines that hold them.

Re-serializing YAML would reorder keys, change quoting and touch blank values, so every
proposed change would come with unrelated churn. Instead each change replaces the text of
one value in place, keeping the key, indentation and quote style; everything else in the
file, including the Markdown body, is left byte for byte as it was.
"""

import re

from fdncheck.records.foundation import FRONT_MATTER


class EditError(ValueError):
    pass


def _render(old_raw: str, new: str) -> str:
    """Write ``new`` in the same quote style as the old value."""
    stripped = old_raw.strip()
    if stripped[:1] == "'" and stripped[-1:] == "'":
        return "'" + new.replace("'", "''") + "'"
    if stripped[:1] == '"' and stripped[-1:] == '"':
        return '"' + new.replace("\\", "\\\\").replace('"', '\\"') + '"'
    return new


def _unquote(raw: str) -> str:
    raw = raw.strip()
    if len(raw) >= 2 and raw[0] == raw[-1] and raw[0] in "'\"":
        return raw[1:-1]
    return raw


def replace_value(text: str, field: str, old: str, new: str) -> str:
    """Replace ``old`` with ``new`` for ``field``, as a scalar (``field: old``) or a list item (``- old``)."""
    match = FRONT_MATTER.match(text)
    if not match:
        raise EditError("no front matter")
    start, end = match.span(1)
    lines = text[start:end].splitlines(keepends=True)
    key = re.compile(rf"^{re.escape(field)}:(?P<sep>[ \t]*)(?P<value>.*?)(?P<trail>[ \t]*)(?P<eol>\r?\n?)$")
    item = re.compile(r"^(?P<indent>[ \t]*)-(?P<sep>[ \t]+)(?P<value>.*?)(?P<trail>[ \t]*)(?P<eol>\r?\n?)$")
    top = re.compile(r"^[^\s#-][^:]*:")
    for i, line in enumerate(lines):
        found = key.match(line)
        if not found:
            continue
        if _unquote(found["value"]) == old:
            lines[i] = f"{field}:{found['sep'] or ' '}{_render(found['value'], new)}{found['trail']}{found['eol']}"
            return text[:start] + "".join(lines) + text[end:]
        if found["value"].strip():
            raise EditError(f"{field} holds {found['value']!r}, not {old!r}")
        for j in range(i + 1, len(lines)):
            if top.match(lines[j]):
                break
            entry = item.match(lines[j])
            if entry and _unquote(entry["value"]) == old:
                value = _render(entry["value"], new)
                lines[j] = f"{entry['indent']}-{entry['sep']}{value}{entry['trail']}{entry['eol']}"
                return text[:start] + "".join(lines) + text[end:]
        raise EditError(f"{field} has no item {old!r}")
    raise EditError(f"no {field} in front matter")


def apply(text: str, changes: list[tuple[str, str, str]]) -> str:
    """Apply (field, old, new) changes in order."""
    for field, old, new in changes:
        text = replace_value(text, field, old, new)
    return text
