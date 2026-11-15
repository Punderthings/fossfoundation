# SPDX-License-Identifier: Apache-2.0
"""Update detection: compare a record with what was observed and decide, with fixed rules.

Pure functions only: no network and no file access.
"""

from dataclasses import dataclass
from typing import Literal

from fdncheck.fetch import Snapshot

Action = Literal["update", "flag", "unchecked", "ok"]


@dataclass(frozen=True)
class Finding:
    """One decision about one value.

    update: change the value in the record (only rules marked so in the catalog and policy).
    flag: a person should check it; nothing is changed.
    unchecked: the value couldn't be checked (blocked, timed out, needs JavaScript).
    ok: the value checked out.
    """

    identifier: str
    field: str
    current: object
    action: Action
    rule: str
    reason: str
    proposed: object | None = None
    snapshot: Snapshot | None = None

    @property
    def key(self) -> str:
        """Stable key for de-duplicating the same item across runs."""
        return f"{self.identifier}:{self.field}:{self.rule}:{self.current}"
