# SPDX-License-Identifier: Apache-2.0
"""Load _foundations records (YAML front matter plus a short Markdown body)."""

import datetime
import re
from dataclasses import dataclass
from pathlib import Path

import yaml

FRONT_MATTER = re.compile(r"\A---[ \t]*\n(.*?)^---[ \t]*$", re.MULTILINE | re.DOTALL)


@dataclass(frozen=True)
class Record:
    identifier: str
    path: Path
    text: str  # the whole file, exactly as read
    data: dict  # parsed front matter


class RecordError(ValueError):
    pass


def parse(text: str, path: Path) -> dict:
    match = FRONT_MATTER.match(text)
    if not match:
        raise RecordError(f"{path}: no YAML front matter")
    try:
        data = yaml.safe_load(match.group(1))
    except yaml.YAMLError as exc:
        raise RecordError(f"{path}: invalid YAML: {exc}") from exc
    if not isinstance(data, dict):
        raise RecordError(f"{path}: front matter is not a mapping")
    return data


def load(path: Path) -> Record:
    text = path.read_text(encoding="utf-8")
    data = parse(text, path)
    identifier = data.get("identifier")
    if not identifier:
        raise RecordError(f"{path}: no identifier")
    return Record(str(identifier), path, text, data)


def load_id(root: Path, identifier: str) -> Record:
    path = root / "_foundations" / f"{identifier}.md"
    if not path.exists():
        raise RecordError(f"no foundation record {path}")
    return load(path)


def ids_in(folder: Path) -> frozenset[str]:
    """Identifiers available in a collection folder, from file names (e.g. _entities, _sponsorships)."""
    return frozenset(p.stem for p in folder.glob("*.md"))


def jsonable(data: dict) -> dict:
    """Front matter as JSON Schema sees it: YAML dates become ISO strings."""

    def convert(value: object) -> object:
        if isinstance(value, (datetime.date, datetime.datetime)):
            return value.isoformat()
        if isinstance(value, list):
            return [convert(v) for v in value]
        if isinstance(value, dict):
            return {k: convert(v) for k, v in value.items()}
        return value

    return {k: convert(v) for k, v in data.items()}
