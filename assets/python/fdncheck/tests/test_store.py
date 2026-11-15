# SPDX-License-Identifier: Apache-2.0
from conftest import DictFetcher, snap

from fdncheck.fetch.store import SavingFetcher, StoredFetcher, load, save


def test_save_and_load_round_trip(tmp_path):
    original = snap("http://a.org/x", redirects=[(301, "https://a.org/x")], body=b"\x00binary\xff")
    loaded = load(save(original, tmp_path))
    assert loaded == original
    assert loaded.sha256 == original.sha256


def test_saving_then_replaying_gives_the_same_snapshots(tmp_path):
    page = snap("https://a.org/")
    inner = DictFetcher({"https://a.org/": page})
    assert SavingFetcher(inner, tmp_path).get("https://a.org/") == page
    assert StoredFetcher(tmp_path).get("https://a.org/") == page


def test_missing_snapshot_is_an_error_snapshot(tmp_path):
    s = StoredFetcher(tmp_path).get("https://a.org/none")
    assert (s.status, s.error) == (0, "not-in-snapshot-store")
