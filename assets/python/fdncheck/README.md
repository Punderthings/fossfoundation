<!-- SPDX-License-Identifier: Apache-2.0 -->
# fdncheck

Checks each [`_foundations/`](../../../_foundations/) record against the foundation's own
website, using fixed rules that maintainers can read and rerun, and proposes a small edit to
that one record plus a list of things a person should check. It never uses an LLM and never
writes descriptive text. The design, its decisions and the later phases are in
[the checker plan](../../../_prompts/2026-11-14-foundation-website-checker-plan.md); how
foundation data is sourced is on [How We Source Data](https://fossfoundation.info/data#sourcing).

This is **phase 1**: URL fields (class A) and references to other collections (class G).

## What it checks

| Check | Result |
| --- | --- |
| A URL field permanently redirects (301 or 308 at every hop) to another URL on the same site | **update**: the value becomes the final URL (an original `#fragment` is kept) |
| A redirect to an equivalent URL (only a trailing slash, letter case or default port differs) | fine, no change |
| A temporary redirect (302, 303, 307), or a permanent one to another site | **flag**: please check; not changed |
| HTTP 404 or 410, other 4xx and 5xx errors, or a redirect loop | **flag**: please check; never removed |
| HTTP 401, 403, 429 or 503, robots.txt disallows us, a timeout or a network error | **could not check** |
| A page that shows almost no text without JavaScript | fine for now; JavaScript rendering comes in phase 2 |
| `identifier` differs from the file name, or `sponsorships` / `subOrganization` names a missing `_sponsorships/` / `_entities/` file | **flag** |

"Same site" means the same host, ignoring a leading `www.`, or one host being a subdomain of
the other. Values that aren't `http(s)` URLs (for example `mailto:`) are not fetched.
`fdncheck fields` prints, for every schema field, its class and whether fdncheck may change it;
that table lives in [`records/catalog.py`](src/fdncheck/records/catalog.py).

## Use

Python 3.14+ and [uv](https://docs.astral.sh/uv/):

```sh
cd assets/python/fdncheck
uv sync --group test
uv run fdncheck fields                          # how each field is checked
uv run fdncheck fetch blender                   # status and redirects of each URL
uv run fdncheck check blender                   # the review report (read-only)
uv run fdncheck check blender --save snaps/     # ...and keep every page fetched
uv run fdncheck check blender --offline snaps/  # replay those pages, no network
uv run fdncheck propose blender                 # the proposed edit, as a diff
uv run fdncheck propose blender --write --commit-message msg.txt
uv run pytest
uvx ruff check
```

`check` and `propose` also take `--json FILE` (findings with the source of each: requested
and final URL, status, redirect chain, fetch time and page hash), `--report FILE` (the
Markdown report) and `--all` (also list values that checked out fine). `--save` writes one
JSON file per URL, so a reviewer can rerun `--offline` and get the same findings and diff.
Saved pages are other people's content: keep them out of this repository.

`propose --write` edits only the lines whose values change, keeping key order, quoting and
the body text. Open the PR yourself; `--commit-message` writes a message in the searchable
form every checker change uses:

```text
fdncheck(blender): update securityurl

- securityurl: http://… -> https://… (redirect-permanent-same-site)

Foundation: blender
Checked-by: fdncheck/0.1.0
Checked-on: 2026-11-15
```

Find one foundation's checker changes with `git log --grep='^Foundation: blender$'`, or on
GitHub with `"fdncheck(blender)"`. Add the usual `Posted by … on behalf of …` line and your own
attribution as AGENTS.md asks.

## Etiquette

Requests send the User-Agent `fdncheck/<version> (+https://fossfoundation.info/data#sourcing)`,
honor robots.txt (RFC 9309: a missing robots.txt allows, a server error disallows), wait at
least one second between requests to the same host, follow at most 10 redirects, read at most
5 MB per page, and fetch each URL once per run even when several fields share it. A site that
blocks automated clients is reported as "could not check"; fdncheck doesn't try to get past it.

## Layout

One package per kind of work, with data flowing one way:

| Package | Job | Network? |
| --- | --- | --- |
| [`fetch`](src/fdncheck/fetch/) | Web scraping: `HttpFetcher` returns a `Snapshot` (final URL, status, every redirect hop, body, time); `store` saves and replays them | **only here** |
| [`extract`](src/fdncheck/extract/) | Pure functions from a `Snapshot` to `Observation`s (title, needs-JavaScript) | no |
| [`records`](src/fdncheck/records/) | Our data and schema: load records, validate them, and the field catalog | no |
| [`detect`](src/fdncheck/detect/) | Update detection: the URL policy and joins, giving `Finding`s (update, flag, unchecked, ok) | no |
| [`propose`](src/fdncheck/propose/) | Output: minimal front-matter edit, Markdown report, JSON findings, commit message | no |

[`check.run_check`](src/fdncheck/check.py) runs them for one foundation, and
[`cli.py`](src/fdncheck/cli.py) is the command line.

Tests use small hand-written pages and `httpx.MockTransport`; they never use the network.

## Dependencies

| Package | License | Used for |
| --- | --- | --- |
| [httpx](https://www.python-httpx.org/) | BSD-3-Clause | HTTP, with each redirect recorded |
| [beautifulsoup4](https://www.crummy.com/software/BeautifulSoup/) (with soupsieve) | MIT | HTML parsing |
| [PyYAML](https://pyyaml.org/) | MIT | Reading front matter |
| [jsonschema](https://python-jsonschema.readthedocs.io/) | MIT | Validating records against `foundations-schema.json` |
| [pytest](https://pytest.org/) (tests only) | MIT | Tests |
