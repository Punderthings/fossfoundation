<!-- SPDX-License-Identifier: Apache-2.0 -->
# Check foundation data against foundation websites with deterministic scrapers

2026-11-14 · Shane Curcuru, with Claude

Status: decided (2026-11-15, see Decisions); implementation not started. **SC:** comments, answers added.
Updated 2026-11-15 to follow [How we source each dataset](2026-11-15-data-sourcing-levels.md) (#99).

## Prompt

> The project's goals are to have fact-based updates of our datasets run by deterministic
> web scraping code that maintainers can review, and could manually run, not agentic runs
> to gather data. Maintainers need to see and understand how any regular "update our data
> from scraping websites" processes happen.
>
> Make a comprehensive plan for how we could automate checking and potentially updating
> existing _foundations data from a current web scrape of each foundation's actual URLs.
> Ask questions when any good engineering practices or "keep all data factual with some
> source" techniques would appear to differ from the list of features here:
>
> - Tooling should all be in python, with clear APIs and a well-defined architecture.
> - Tools should be useable from the command line for testing and maintainer use.
> - Clearly separate code so it's clear what kind of work each module does:
>   - web scraping code (like checking JavaScript when needed to load site data)
>   - data or schema analysis code of existing _foundation data fields that we are trying
>     to check versus current state
>   - update detection code, that reviews web site data against _foundation data, and
>     detects if we should make a change
> - For each foundation, the end result should be a PR with updates for just that
>   foundation, plus brief commentary or list of any changes that we're not sure of.
> - Maintainers would then review the PRs to ensure human eyes are reviewing changes
> - Also plan a simple workflow in GitHub that maintainers could automate on a schedule

## Summary

- **A new Python tool, `fdncheck`**, in `assets/python/fdncheck/` (uv project, Python
  3.14+, pytest, ruff), in the same shape as [fdncrosswalk](../assets/python/fdncrosswalk/).
  It reads `_foundations/<id>.md`, fetches only that foundation's own URLs, and writes
  a proposed edit to that file plus a review report. It never calls an LLM and never
  writes free text of its own.
- **Five layers, one job each.** `fetch` (the only network code, with optional
  JavaScript rendering), `extract` (pure functions from a saved page to observed
  values), `records` (our data and schema: what each field means and how it can be
  checked), `detect` (compare record against observations and decide), and `propose`
  (write the minimal file edit and the PR text). Shane's three areas map onto these;
  extraction is split out of scraping so it can be tested without a network, and the
  writer is split out of detection so detection never touches files.
- **Three outcomes per field: update, flag, or nothing.** Only facts with a
  machine-checkable source on the foundation's own site are changed in the diff
  (for example a URL that now permanently redirects). Everything heuristic goes in the
  PR body as "not sure, please check", with the source URL. Descriptive text fields are
  never edited by the tool; it only reports that the page they came from changed.
- **Every finding carries its evidence in the PR, not in new files**: the URL fetched,
  the final URL, the HTTP status, the time, a short quote or selector of what was
  matched, and the rule that matched it. Following the
  [sourcing levels](2026-11-15-data-sourcing-levels.md) decided in #99, foundation
  records get no per-field sources and no evidence files; the PR text and git history
  are the record, and every checker PR, commit and issue carries the same searchable
  tags (see [Finding one foundation's history](#finding-one-foundations-history)).
- **Items a person should check go in one summary issue per run**, covering every
  foundation scanned in that run, so maintainers investigate them in one batch.
- **One branch and one draft PR per foundation with changes**, created by a small
  script in a GitHub Actions workflow, opened by a GitHub App that maintainers start by hand or on a schedule. The same
  commands run on a laptop with the same result, using `--offline` against saved pages.
- **Rollout in phases**: URL health and redirects first (highest value, lowest risk),
  then structured facts, then the scheduled workflow, then change-watch for text
  fields.

## What exists today

- **96 foundation records**, one Markdown file each, with YAML front matter described by
  [foundations-schema.json](../_data/foundations-schema.json). About 25 fields are URLs
  (`format: url`), about 20 are short facts (names, dates, country, tax id, counts, yes/no
  values), and about 15 are short descriptive text.
- **No per-field sources or "last checked" dates** in `_foundations`, and none are
  wanted. [How We Source Data](../_pages/data.md) (`/data#sourcing`, from #99) says
  foundation records need a maintainer's check against the organization's own site,
  linked in the PR, and that "the pull request, with its links, and git history are the
  record". AGENTS.md and CONTRIBUTING.md say the same. That is the level this tool
  works to: it makes the reviewer's check fast and repeatable, not a new kind of
  provenance. Crosswalk-style evidence objects stay with the crosswalk, which needs a
  higher bar.
- **Precedents to follow**: per-source CSS selectors for sponsor lists in `_sponsorships/*.md`; provenance in
  `history/sponsorships/`; the stubbed `fetch` arguments in fdncrosswalk's `probes.py`.
- **Earlier refreshes were agentic.** PR #96 (Blender, Bytecode Alliance) used an LLM to
  read the sites and summarize them. The values were checked, but nobody can rerun that
  process and get the same answer, which is what this plan replaces.
- **`_foundations/list.json` can't be regenerated.** It holds each foundation's website
  domain, `commonName` and `legalName`, and its generator
  (`assets/ruby/openapi_builder.rb`) calls `FoundationReporter.get_yamldataset`, which no
  longer exists. Any checker PR that changes `website` or `legalName` leaves it stale
  until that is fixed, so fixing it is a prerequisite for phase 2 (separate PR).
- **Lessons from the review of PR #58** (leadership data and its refresh script): persist state, watch every source URL, never fall back silently to a
  different page, hash extracted content rather than whole pages, and de-duplicate
  reports across runs. This plan builds those in.

## Goals and non-goals

Goals, in the order of AGENTS.md:

1. Every value the tool proposes traces to a URL on the foundation's own site that a
   reviewer can open, plus the exact rule that produced it.
2. Same inputs give the same output: given the saved pages, anyone gets the same
   findings and the same diff.
3. The tool proposes; a maintainer decides. Nothing merges without review.
4. Small diffs: only the changed lines of one foundation file per PR.

Non-goals:

- Writing or rewording `description`, `governanceOrg`, or any other descriptive text.
  AGENTS.md says officers get a say in descriptive text, and deterministic code can't
  summarize a page.
- Adding new foundations, deleting values, or renaming identifiers.
- Fetching third-party registries (IRS, GLEIF, Wikidata, national company registers).
  They change slowly, and reviewing them stays a maintainer task (decided 2026-11-15).
- Archiving the pages it checks (for example in the Internet Archive); see the future
  question under Decisions.
- Replacing the sponsor scrapers in `assets/ruby/` (a separate migration).

## Field catalog: what can be checked, and how

Each field's class is stored in the schema itself, as an `x-check` keyword on its
property in `_data/foundations-schema.json` (decision 10): `url` (A), `fact` (C),
`count` (D), `choice` (E), `text` (F) or `reference` (G). Class B uses the `url`
fields. The `records` layer reads it, and a test fails if a field has no class or one
that disagrees with its type or format.

| Class | Fields | Check | Can update? |
| --- | --- | --- | --- |
| **A. URL fields** | `website`, `contacturl`, `boardurl`, `teamurl`, `missionurl`, `bylawsurl`, `projectsList`, `eventurl`, `budgeturl`, `donateurl`, `sponsorurl`, `securityurl`, `ethicsPolicy`, `conducturl`, `conductEvents`, `conductProjects`, `diversityPolicy`, `brandPolicy`, `brandUse`, `logo` | Fetch; record status, redirect chain, final URL | Yes, for a permanent redirect (301/308) to the same registrable domain, or `http:` to `https:` at the same path. Off-domain redirects, temporary redirects and errors are flagged, never applied. |
| **B. Missing URL discovery** | the same URL fields when empty | Look for links on the homepage and its footer: `rel` values (`license`, `privacy-policy`), well-known paths (`/.well-known/security.txt`), and link text in a short, reviewed word list per field ("Code of Conduct", "Bylaws", "Donate") | Flag only. Link text is a heuristic. |
| **C. Structured facts** | `legalName`, `foundingDate`, `addressCountry`, `addressRegion`, `taxID`, `wikidataId`, `logo` | Schema.org JSON-LD or microdata on the site (`Organization.legalName`, `foundingDate`, `address`, `taxID`, `sameAs` to Wikidata, `logo`); footer legal lines matched by narrow patterns (e.g. "Stichting …", "… is a 501(c)(3)", "EIN 12-3456789", "KvK 12345678") | Update only from Schema.org markup the foundation itself published, and only when the existing value is empty or the markup is unambiguous. Footer pattern matches are flagged. |
| **D. Counts** | `boardSize`, `numberOfEmployees` | Count items matched by a per-foundation selector on `boardurl` / `teamurl` | Flag only, with the count and the selector. Rosters include emeritus, observers and staff. |
| **E. Enumerations and yes/no** | `newProjects`, `brandReg`, `logoReg`, `claPolicy`, `budgetTransparent`, `nonprofitStatus`, `boardType`, `funding`, `licenses`, `softwareType`, `budgetUsd`, `budgetYear`, `conductLinked`, `fiscalHost` | Not inferred. Optional per-foundation rule can flag a phrase appearing or disappearing (e.g. "no longer accepting new projects") | Never |
| **F. Descriptive text** | `description`, body sentence, `governanceOrg`, `governanceTech`, `projectsNotable`, `projectsServices`, `conductReport`, `diversityDescription`, `brandComments`, `sponsorList`, `brandPrimary`, `brandSecondary` | Change-watch: hash the extracted main text of the page the field came from (the matching URL field, e.g. `missionurl` for `description`) and report when it changes | Never. The PR body says "the mission page changed since <date>; consider re-reading it". |
| **G. Joins and generated** | `identifier`, `sponsorships`, `subOrganization`, `conductSource` | Validate that referenced ids exist | Never |

Per-field confidence is stated in the schema, not guessed at run time. Moving a field
to another class is a one-line, reviewed schema change; letting a class update values is
a reviewed change to `POLICY` in `records/catalog.py`.

## Architecture

```text
assets/python/fdncheck/
  pyproject.toml          uv project; console script `fdncheck`
  README.md
  src/fdncheck/
    fetch/                Web scraping: the ONLY package that uses the network
      __init__.py         Fetcher protocol, Snapshot dataclass
      http.py             Static fetch (redirect chain, robots.txt, rate limit, cache)
      browser.py          Optional JavaScript rendering with Playwright
      store.py            Save and load snapshots on disk (for --offline and review)
    extract/              Pure functions: Snapshot -> list[Observation]
      links.py            URL health, redirects, link discovery
      structured.py       JSON-LD, microdata, RDFa (Schema.org Organization)
      patterns.py         Narrow regexes for legal names and tax ids
      text.py             Main-text extraction and hashing for change-watch
      rules.py            Load per-foundation rules (selectors, extra pages)
    records/              Our data and schema analysis; no network, no HTML
      foundation.py       Load a _foundations file (front matter + body), validate
      catalog.py          Field catalog: class, source URL field, check, may-update
      schema.py           Load foundations-schema.json; catalog-vs-schema coverage
    detect/               Update detection; pure, no I/O
      compare.py          Record + observations -> list[Finding]
      policy.py           Normalization (trailing slash, case, http->https) and the
                          update/flag/none decision table
    propose/              Output; writes files, never fetches
      frontmatter.py      Minimal line edit of changed keys only
      report.py           PR body, run summary issue (Markdown), JSON findings
    cli.py                Subcommands below
  rules/<id>.yaml         Optional per-foundation rules (see below)
  tests/
    fixtures/             Small synthetic HTML pages and records
    test_*.py
.github/scripts/fdncheck-pr.sh   git + gh only: branch, commit, push, open/update PR
.github/workflows/fdncheck.yml   Manual and scheduled runs
```

Data flows one way:

```text
records.load(id) ──► catalog says which URLs to fetch
        │
fetch.get(url) ──► Snapshot ──► store (optional)
        │
extract.*(snapshot, rules) ──► Observations
        │
detect.compare(record, observations, catalog) ──► Findings
        │
propose.* ──► edited _foundations/<id>.md, report.md, findings.json
```

### Core types

```python
@dataclass(frozen=True)
class Snapshot:            # fetch
    requested_url: str
    final_url: str
    status: int
    redirects: tuple[tuple[int, str], ...]   # (status, location) per hop
    fetched_at: datetime                     # UTC
    content_type: str
    body: bytes
    rendered: bool                           # True if JavaScript ran
    sha256: str
    error: str | None                        # DNS, TLS, timeout, robots-disallowed

@dataclass(frozen=True)
class Observation:         # extract
    field: str | None      # catalog field it bears on, if any
    value: object
    method: str            # e.g. "jsonld:Organization.legalName", "redirect:301"
    source_url: str        # final URL of the snapshot
    locator: str           # CSS selector, JSON path or regex that matched
    excerpt: str           # <= 200 chars of matched text, for the reviewer
    snapshot_sha256: str

@dataclass(frozen=True)
class Finding:             # detect
    identifier: str
    field: str
    current: object
    proposed: object | None
    action: Literal["update", "flag", "none"]
    reason: str            # one sentence, from a fixed template per rule
    evidence: tuple[Observation, ...]
```

`Finding.reason` comes from fixed templates keyed by rule, so two runs on the same pages
produce identical PR text.

### Layer rules

- **fetch** knows nothing about foundations or fields. It takes a URL and options and
  returns a `Snapshot`, never raises on HTTP errors (they are data), and doesn't follow
  links on its own. Defaults: an identifying User-Agent naming the project and its site
  (no personal address), robots.txt honored, one request per second per host, 30 s
  timeout, at most 10 redirects, at most 15 pages per foundation, response size cap.
  `browser.py` is used only when a foundation's rule says `render: js`, or when the
  static page has no `<body>` text and a rule allows fallback. Rendering waits for
  network idle with a fixed timeout and records `rendered=True`.
- **extract** is pure: bytes in, observations out. It never fetches a linked page itself;
  if a rule needs a second page, the orchestrator fetches it and calls extract again.
  Every extractor is unit-tested from fixtures.
- **records** knows the schema and our files, not HTML. It also answers "which URL does
  field X come from" for change-watch, and runs the same JSON Schema validation as the
  site build.
- **detect** is pure and deterministic. It normalizes both sides (URL canonicalization,
  whitespace, case for country codes, ISO dates) before comparing, applies the catalog's
  may-update setting, and never proposes an empty value.
- **propose** edits only the lines of keys whose value changes, keeping key order,
  quoting style (`'2002'` stays quoted), comments and the body text. A round-trip test
  proves an unchanged record produces a byte-identical file. It does not run git.

### Per-foundation rules

Generic extraction works for URL health and Schema.org markup. Counting board members or
finding a footer legal line needs site knowledge, written down where reviewers can see
it, the way `_sponsorships/*.md` holds sponsor selectors:

```yaml
# SPDX-License-Identifier: CC0-1.0
# rules/blender.yaml
render: static            # or js
pages:                    # extra pages to fetch, by field they inform
  boardurl: https://www.blender.org/about/people/
selectors:
  boardSize:
    url_field: boardurl
    css: "section#board .person h3"
legal_patterns:
  - "Stichting Blender Foundation"
```

Rules are optional; a foundation without one gets generic checks only. A rule that stops
matching (zero results) is a flag ("selector for boardSize matched nothing; the page may
have been redesigned"), never a silent zero.

### Command line

```text
fdncheck fields                       Print the field catalog (class, may-update, source field)
fdncheck fetch ID [--save DIR]        Fetch the foundation's URLs; print a status table
fdncheck check ID [--offline DIR]     Fetch (or load saved pages), extract, detect; print findings
fdncheck propose ID [--offline DIR] [--write] [--report FILE] [--json FILE]
                                      As check, then show (or with --write, apply) the edit
fdncheck run [--all | ID...] [--max N] [--out DIR]
                                      Batch for CI: one folder per foundation with the edit,
                                      report.md and findings.json; exit 0 even when
                                      sites fail, non-zero only on tool errors
fdncheck validate [ID...]             Schema-validate records and rules
```

`check` is read-only and the command a maintainer runs first. `--offline DIR` replays a
saved run, so a reviewer can reproduce the exact findings of a PR from its uploaded
snapshots.

### Dependencies (to approve before anything is installed)

All need ASF Category A licenses. Approved 2026-11-15, with Playwright moved to
phase 2.

| Package | License | Why | Alternative |
| --- | --- | --- | --- |
| ~~`httpx`~~ | BSD-3-Clause | HTTP with redirect history and timeouts | stdlib `urllib`, chosen instead (decision 5) |
| `beautifulsoup4` | MIT | HTML parsing, CSS selectors via `soupsieve` (MIT) | `lxml` (BSD-3-Clause) alone |
| `extruct` | BSD-3-Clause | JSON-LD, microdata, RDFa in one call | parse `<script type="application/ld+json">` ourselves |
| `PyYAML` | MIT | Read front matter and rules | `ruamel.yaml` (MIT) if we also want round-trip writing |
| `jsonschema` | MIT | Validate records, as fdncrosswalk does | none |
| `playwright` | Apache-2.0 | JavaScript rendering, opt-in per foundation | skip JS sites in phase 1 |
| `pytest`, `ruff` | MIT | test and lint (dev only) | none |

**SC:** All above dependency packages are approved, except skip JS sites in phase 1: add Playwright dependency in phase 2.

Playwright also downloads a browser build. It is added in phase 2, in an optional
dependency group (`uv sync --extra browser`), so maintainers who don't need JS rendering
never install it. Phase 1 skips sites that need JavaScript and reports them under
"Could not check". `extruct` is also first used in phase 2.

## Review and the PR

### What a PR looks like

One branch per foundation, `fdncheck/<id>`, and one draft PR titled
`fdncheck(<id>): update <fields>`, labelled `fdncheck`, only for a foundation that has a
change to propose. The diff touches only `_foundations/<id>.md`. The body:

```markdown
## Summary
fdncheck 0.1.0 checked 14 URLs for blender on 2026-12-01 (UTC).

### Changes in this PR (verified by rule)
| Field | Was | Now | Source | Rule |
| securityurl | http://… | https://… | https://… (301) | redirect-permanent-same-domain |

### Please check (not changed)
- `boardurl` returns 404: https://… (was fine on 2026-11-01). Not removed.
- `boardSize`: 5 names match `section#board h3` on https://…; record says 4.
- `missionurl` page text changed since 2026-11-01 (hash a1b2… → c3d4…);
  `description` may need a human re-read.

### Could not check
- https://… blocked by robots.txt

Reproduce: `uv run fdncheck propose blender --offline <artifact>`; snapshots are in
the workflow run's artifacts for 90 days. These items are also in the run's summary
issue (#NNN).

Foundation: blender · Checked-by: fdncheck/0.1.0 · Checked-on: 2026-12-01

Posted by fdncheck on behalf of the FOSSFoundation.info maintainers
```

The PR template checklist is filled in by the script; only items the tool did are
ticked, so "I verified the site builds" stays for the reviewer (or for the required
`build` check).

### Items to check: one summary issue per run

Every run, manual or scheduled, ends with one issue titled
`fdncheck run <YYYY-MM-DD>: <m> items to check in <k> foundations`, labelled
`fdncheck`. It batches the "Please check" and "Could not check" items for every
foundation scanned in that run, grouped under a `fdncheck(<id>)` heading per
foundation, and links that run's PRs and workflow artifacts. A foundation with items
but no changes appears only there. Maintainers work through the issue and close it;
any fix is a normal PR.

### Finding one foundation's history

Every checker output names the foundation `identifier` the same way, so one
foundation's checks are easy to find in git and on GitHub (decision 5 in #99):

| Where | Convention | How to search |
| --- | --- | --- |
| Branch | `fdncheck/<id>` | `git branch -r --list 'origin/fdncheck/*'` |
| PR titles and summary issue headings | `fdncheck(<id>)` | GitHub: `label:fdncheck "fdncheck(blender)"` (finds PRs and summary issues) |
| Label | `fdncheck` on every PR and summary issue | GitHub: `label:fdncheck` |
| Commit subject | `fdncheck(<id>): update <fields>` | `git log --oneline --grep='^fdncheck(blender)'` |
| Commit trailers | `Foundation: <id>`, `Checked-by: fdncheck/<version>`, `Checked-on: <YYYY-MM-DD>` | `git log --grep='^Foundation: blender$'` |
| PR body | last line `Foundation: <id> · Checked-by: … · Checked-on: …` | GitHub full-text search |

The trailers survive because this repository merges PRs with merge commits rather than
squashing. `git log _foundations/<id>.md`, the method `/data#sourcing` already gives,
still lists every change to a record, by people or by the checker; the tags pick out
the checker's own changes and checks. The checker is not generative AI, so its commits
carry `Checked-by:` rather than `Generated-by:`.

### Avoiding noise

- The PR body and diff are deterministic, so the script hashes them. If an open PR for
  the same foundation already has the same hash, nothing is pushed. If it differs, the
  branch is force-updated and the body replaced (one open PR per foundation, never a
  pile).
- An item that was in the previous summary issue and is still found is listed under
  "Still open since <date>" rather than as new. The script reads the previous items
  from a hidden `<!-- fdncheck-state … -->` JSON block in the last summary issue (item
  keys and, from phase 5, page hashes), so no state is committed to the repository.
  Opening a new summary issue closes the previous one with a link to it.
- `run --max N` caps PRs per run (default 10), and the schedule rotates through
  foundations so each is checked about monthly without a 96-PR burst.

## GitHub workflow

```yaml
# .github/workflows/fdncheck.yml (sketch; actions pinned to full SHAs when written)
name: Check foundations against their websites
on:
  workflow_dispatch:
    inputs:
      ids:     { description: "Foundation ids, space separated (blank = rotation)", required: false }
      dry_run: { description: "Report only, no PRs", type: boolean, default: true }
  schedule:
    - cron: "17 6 * * 1"        # Mondays 06:17 UTC; about a quarter of foundations each week
permissions:
  contents: write
  pull-requests: write
concurrency: { group: fdncheck, cancel-in-progress: false }
jobs:
  check:
    runs-on: ubuntu-latest
    timeout-minutes: 60
    steps:
      - uses: actions/checkout@<sha> # vX
      - uses: astral-sh/setup-uv@<sha> # vX
      - run: uv sync --project assets/python/fdncheck --frozen
      - run: uv run --project assets/python/fdncheck fdncheck run ${{ inputs.ids || '--rotation' }} --out out/
      - uses: actions/upload-artifact@<sha> # vX   (snapshots + reports, 90 days)
      - if: ${{ !inputs.dry_run }}
        run: .github/scripts/fdncheck-pr.sh out/
        env: { GH_TOKEN: <installation token from the GitHub App, see below> }
```

Notes:

- `fdncheck-pr.sh` uses only `git` and the `gh` CLI preinstalled on GitHub runners, so
  no third-party PR action is needed. It opens PRs as drafts, adds a `fdncheck` label,
  requests review from the maintainers, and writes the run's summary issue.
- **A GitHub App opens the PRs and issues** (decided 2026-11-15). PRs opened with the
  default `GITHUB_TOKEN` don't trigger other workflows, so the required `build` check
  would never run on them. The workflow turns the App's private key (a repository
  secret) into a short-lived installation token with GitHub's
  `actions/create-github-app-token` action, pinned to a SHA.

### The GitHub App, for maintainers

Phase 3 adds a page for maintainers (`_pages/` or the tool README; it is linked from
both) that explains, in plain language:

- **What it can do**: installed only on this repository, with `contents: write`
  (push `fdncheck/*` branches), `pull_requests: write` and `issues: write`, and
  nothing else (no admin, workflows, secrets or org access).
- **What it can't do**: approve or merge; branch protection on `main` still requires a
  maintainer's review, and the workflow only pushes `fdncheck/*` branches.
- **Where the key lives**: one repository secret, readable only by workflows on `main`
  (not by PRs from forks); who can see and rotate it, and how to rotate or revoke it.
- **Risks and limits**: anyone who can change the workflow on `main` can use the token,
  so workflow changes get the same review as code; the JavaScript-rendering job gets no
  token (see Risks); how to turn the whole thing off (disable the workflow, or suspend
  the App).
- **Who owns it**: the App is owned by the repository's organization, not a person.
- A manual run defaults to `dry_run: true`: it uploads the reports as artifacts and
  writes them to the run summary, and opens nothing.
- `--rotation` picks the foundations whose number modulo 4 matches the ISO week modulo
  4, from the sorted list of ids, so the choice is predictable and needs no state.

## Testing

- No network in tests, as AGENTS.md requires. `fetch` takes a transport that tests
  replace with canned responses (including redirect chains, 404s, timeouts and
  robots.txt refusals). `browser.py` is tested only behind a marker that is skipped by
  default; its output is a `Snapshot` like any other.
- **Fixtures are synthetic.** Saved copies of foundation pages are other people's
  copyrighted pages, so committing them would need REUSE annotations for third-party
  content. Tests use small hand-written HTML that reproduces the structures we parse
  (a JSON-LD block, a footer with a legal line, a board list), licensed like our code.
  Real snapshots live only in workflow artifacts and maintainers' local `--save` folders.
- Golden tests: fixture record + fixture snapshots → expected `findings.json`, diff and
  `report.md`. Any change to a rule or template shows up as a reviewed golden-file diff.
- Round-trip test over every real `_foundations/*.md`: load and write with no changes
  gives byte-identical files.
- Catalog coverage test: every property in `foundations-schema.json` has a catalog entry.
- `uv run pytest`, `uvx ruff check`, and `uvx reuse lint` in CI on PRs that touch the
  tool (a small extra job; that is a workflow change to approve with phase 1).

## Rollout

| Phase | Delivers | Changes data? |
| --- | --- | --- |
| 0 | This plan; decisions on the open questions | No |
| 1 | `fdncheck` with `fetch`, `extract.links`, `records`, `detect`, `propose`; classes A and G; `fields`, `fetch`, `check`, `propose` commands; tests | Only when a maintainer runs `propose --write` and opens a PR by hand |
| 2 | Playwright for JavaScript sites; class C (Schema.org and legal patterns, flag-only at first), class D with per-foundation rules for a few foundations; fix `openapi_builder.rb` so `list.json` regenerates (separate Ruby PR, prerequisite) | Same |
| 3 | `run`, `fdncheck-pr.sh`, the summary issue, the GitHub App and its maintainer page, the workflow with `workflow_dispatch` only; dry-run by default | PRs on demand |
| 4 | Schedule turned on after a few manual runs look right | Weekly rotation |
| 5 | Class B discovery and class F change-watch, using page hashes from the state block in the last summary issue | Flags only |
| After | Review utilities shared with fdncrosswalk (fetching, YAML and JSON loading) and combine what both use | No |

Each phase is its own PR. A trial on 3 to 5 foundations of different kinds (a US 501(c)(3)
with a static site, a European Stichting or e.V., a JavaScript-heavy site, a fiscal
sponsor) comes before turning on the schedule.

## Risks

- **Site redesigns** break selectors. Mitigation: zero matches is a flag, never a value;
  generic checks need no selectors.
- **Bot blocking** (Cloudflare challenges, 403 to non-browser clients). Mitigation:
  report "could not check" and move on; don't evade blocks. A site that blocks the
  checker stays a manual review.
- **False confidence from redirects** (a domain sold or parked). Mitigation: same
  registrable-domain rule; off-domain redirects are flags.
- **Load on foundation sites.** About 15 pages per foundation per month, at one request
  per second, honoring robots.txt.
- **Reviewer fatigue.** Caps per run, no duplicate PRs, and one summary issue per run.
- **JavaScript rendering runs third-party code** in the CI runner. The job has a
  write token; rendering should run in a separate job with `contents: read` and no
  token, passing snapshots to the PR job as an artifact.

## Open questions

1. **Where does the evidence live after merge?** `_foundations` has no source or
   checked-date fields, so once a PR merges, the only record of where a value came from
   is the PR text. Options: (a) PR text only, as today; (b) a companion file per
   foundation, e.g. `_data/fdncheck/<id>.json`, holding the last observation per field
   (source URL, date, method, excerpt, page hash) in the crosswalk's evidence shape,
   CC0, updated in each PR; (c) new `source`/`checked` fields in the foundation records
   (a schema change). Recommend (b): it answers CONTRIBUTING's open question, gives
   change-watch and de-duplication the state they need, and leaves `_foundations` and
   its published API alone. It is a new dataset, so it needs your approval.
   **SC:** See PR #99 and review the different rules for evidence; foundation updates generally use the git history for tracking.
3. **What happens to a foundation that has only flags?** (a) Commit only the evidence
   file, so it still gets a PR (needs 1b); (b) one issue per foundation, updated in
   place; (c) a single weekly summary issue. Recommend (a) if 1b is chosen, else (b).
   **SC:** (c) a single summary issue based on whatever scans were done that run; batch these together to report to maintainers for investigation.
4. **Which token opens the PRs?** With the default `GITHUB_TOKEN`, the required `build`
   check won't run on the PRs. Options: (a) a GitHub App installed on the repo,
   with its key as a repository secret (recommended: scoped, not tied to a person);
   (b) a fine-grained personal token from a maintainer (tied to one person,
   expires); (c) default token, and a maintainer closes and reopens or pushes to each
   PR to start the check.
   **SC:** (a), include human-readable documentation about this app so it's easy to understand the security issues for maintainers.
5. **Is "update" allowed at all for facts, or should every change be a flag at first?**
   Recommend: in phases 1 to 3, only URL redirects (class A) are ever applied; class C
   starts as flag-only and moves to update after a trial, field by field.
   **SC:** Agreed with recommend.
6. **Dependencies.** Approve the table above (httpx, beautifulsoup4, extruct, PyYAML,
   jsonschema, optional playwright; pytest and ruff for development), or say which to
   replace with standard-library code.
   **SC:** approved, except move playwright to a phase 2 so we can quickly test phase 1 on basic sites.
7. **Only the foundation's own site?** AGENTS.md prefers it. Third-party registries
   (IRS exempt organization data, GLEIF, national company registers such as the Dutch
   KvK, Wikidata) are more reliable for `legalName`, `taxID` and `foundingDate`. Recommend
   own site only for this tool, with registries as a later, separate checker that only
   flags.
   **SC:** Keep as own sites only; external registries change very slowly and will probably be a maintainer task to review.
8. **Archive snapshots.** Should the tool ask the Internet Archive to save each page it
   cites, and put the archive URL in the evidence, so the citation survives a redesign?
   That adds a third-party call per page; recommend yes, but only on non-dry runs.
   **SC:** No, we do not need this extra work; add a future decision to maintainers asking how important this kind of detailed history is to our project.
9. **Tool name and place.** `fdncheck` in `assets/python/fdncheck/` in this repository,
   or something else? Shared fetch code with fdncrosswalk could later become a small
   library; recommend not sharing until both need the same thing.
   **SC:** Agreed, in this repository, separate code until tested; after we've done several phases and testing make a note to review any shared utilities we can combine.
   
## Decisions

Shane answered every open question on 2026-11-15 (his **SC:** notes above, kept as
written):

1. **Evidence storage: no evidence files.** Foundation updates use the PR and git
   history as the record, per [data sourcing levels](2026-11-15-data-sourcing-levels.md)
   (#99, decision 5). The companion-file design and `propose/evidence.py` are dropped,
   and checker output follows
   [Finding one foundation's history](#finding-one-foundations-history).
2. **Items to check: one summary issue per run**, batching every foundation scanned in
   that run, for maintainers to investigate together.
3. **Token: a GitHub App**, with a plain-language maintainer page on its permissions and
   security ([The GitHub App, for maintainers](#the-github-app-for-maintainers)).
4. **Updates vs flags: as recommended.** Phases 1 to 3 apply only class A URL
   redirects; class C starts flag-only and moves to update field by field after a trial.
5. **Dependencies: approved** (httpx, beautifulsoup4, extruct, PyYAML, jsonschema;
   pytest and ruff for development), with Playwright added in phase 2 so phase 1 can be
   tested quickly on basic sites. **Revised 2026-11-15** (Shane, on #101): use the
   standard library's `urllib` instead of httpx, which pulled in `certifi` (MPL-2.0, ASF
   Category B), "so we can both avoid MPL-2.0 and so we have fewer dependencies by using
   a standard library."
6. **Sources: the foundation's own sites only.** External registries change slowly and
   will probably stay a maintainer review task.
7. **Archive snapshots: no.**
8. **Name and place: `fdncheck` in `assets/python/fdncheck/`**, separate from
   fdncrosswalk until tested; after several phases, review shared utilities to combine.
9. **SC** (#99): lastChecked and lastReviewed are new features, filled in going forward,
   so the checker doesn't report their absence.
10. **SC** (2026-11-15): **each field's check class lives in the schema**, as an
    `x-check` keyword on every property of `_data/foundations-schema.json`, rather than
    in a separate catalog in code. Validators ignore unknown keywords, and the `x-`
    prefix is the OpenAPI extension convention. The code keeps only what each class may
    do (`POLICY`) and a consistency test. Other datasets' schemas can use the same
    keyword when a tool checks them.
11. **SC** (2026-11-15): **`fiscalHost` added to `foundations-schema.json`** as a string,
    using the title and description already in `openapi/v1/foundation-schema.yaml`.
    Records use it for the kind of hosting (`direct`, `indirect`, `full`), so its class
    is `choice`; `fiscalHost` in `sponsorships-schema.json` instead holds a
    `_foundations` identifier.

### Future decision for maintainers

- **How much page history do we need?** SC asked to record this: how important is a
  detailed history of the foundation pages we check (for example archived snapshots of
  each page a change was based on) to the project? Today, workflow artifacts keep each
  run's snapshots for 90 days, and nothing longer.
- **An identifier type for the schemas.** SC: in the future, design a custom schema
  class that stands for an identifier of a foundation, host, sponsor or similar entity,
  so fields such as `fiscalHost`, `sponsorships` and `subOrganization` say what kind of
  identifier they hold and tools can check it exists. Today these use plain strings or
  the `jjresolver~…` format.

## Next step

**Phase 1, as its own PR.** Create `assets/python/fdncheck/` (Python 3.14+, uv) with:

- the `fetch` (static HTTP only), `extract.links`, `records`, `detect` and `propose`
  layers, covering class A (URL health and permanent same-domain redirects, the only
  automatic updates) and class G (referenced ids exist);
- the `fields`, `fetch`, `check` and `propose` commands, with `--offline` replay;
- dependencies beautifulsoup4, PyYAML and jsonschema, with pytest and ruff for
  development, and `urllib` for HTTP (decision 5);
- synthetic HTML fixtures and golden tests with no network, a byte-identical round-trip
  test over every `_foundations/*.md`, a catalog-vs-schema coverage test, and a README;
- the searchable commit subject and trailers above, written by `propose` for a
  maintainer to use when opening a PR by hand.

No workflow, GitHub App, schedule or data change in that PR. When it merges, a
maintainer runs `uv run fdncheck check <id>` on three to five foundations of different
kinds and judges the findings before phase 2.

In parallel, a small separate Ruby PR fixes `openapi_builder.rb` so
`_foundations/list.json` can be regenerated, which phase 2 needs before it can change
`website` or `legalName`.
