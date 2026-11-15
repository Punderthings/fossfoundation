# SPDX-License-Identifier: Apache-2.0
"""The pages behind fixtures/acme-foundation.txt: one of each case the URL policy handles."""

from conftest import snap

A = "https://acme.example.org"
PAGES = {
    "http://acme.example.org/": snap("http://acme.example.org/", redirects=[(301, f"{A}/")]),
    f"{A}/board": snap(f"{A}/board", body=b"<html><title>Board</title><body>" + b"Board members. " * 30 + b"</body>"),
    f"{A}/about": snap(f"{A}/about", redirects=[(301, f"{A}/about/")]),
    f"{A}/donate": snap(f"{A}/donate", redirects=[(302, "https://pay.example.net/acme")]),
    f"{A}/sponsors#list": snap(f"{A}/sponsors#list", redirects=[(308, f"{A}/supporters")]),
    f"{A}/security": snap(f"{A}/security", status=404),
    f"{A}/coc": snap(f"{A}/coc", status=403),
    f"{A}/old-coc": snap(f"{A}/old-coc", redirects=[(301, "https://www.acme.example.org/code-of-conduct")]),
    f"{A}/project-coc": snap(f"{A}/project-coc", redirects=[(301, "https://coc.example.net/")]),
}
