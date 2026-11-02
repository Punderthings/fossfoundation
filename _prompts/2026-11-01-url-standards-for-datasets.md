<!-- SPDX-License-Identifier: Apache-2.0 -->
# Create url naming standards for datasets

2026-10-31 · Shane Curcuru, with Claude

Status: draft proposal (2026-11-02); API version decided (see Decisions), other open
questions waiting.

## Prompt

Propose consistent URL pathing and OpenAPI or similar naming standard(s) for this website and our datasets.

GOALS:

- We have two audiences accessing our URLs; both are important:
  - Open source coders browsing our site: a person should be able to easily understand what a URL path means.
  - Researchers using standards-based tooling to search or auto-discover our datasets.
- Follow well-established standards like REST, OpenAPI, and other research oriented discovery tools around metadata and datasets.
- Maintain our data in existing file formats, so we can track changes with git, have maintainers able to easily review changes, and to keep maintenance simple.
- Have consistent URL naming standards for all datasets, even ones with different aspects or use cases.

IMPORTANT: do not change the existing /_foundations/ dataset because it is widely used and was created before our project scope grew.  Other newer datasets might change some URLs if it helps with consistency across the site.

DATASET ASPECTS:

Our datasets are varied by different aspects: type of data (an organization; a person; detailed tax data, a minimal crosswalk between our sources and ecosyste.ms), update frequency, how accuracy is determined (foundations: officers attest, taxes: assume IRS 990 is correct), hand or tool maintained, most common usage (human users frequently view on web, mostly API access), and more.  Note this list includes datasets that are planned to be added.  

| Dataset                 | Complexity                                                  | Status                                  | Accuracy                       | Uses by priority              |
| ----------------------- | ----------------------------------------------------------- | --------------------------------------- | ------------------------------ | ----------------------------- |
| Foundations             | complex; organization and multiple crosslinks               | existing                                | officer attested               | browsing; API                 |
| Entities                | simple; mostly crosslinks to websites                       | needs building out for more data        | scraped (in future)            | API                           |
| Sponsors                | simple; mostly data to uniquely identify                    | existing                                | derived                        | browsing; API; visualisations |
| Sponsorships            | complex; financial and linking data                         | existing                                | "derived, but checked"         | visualisations; API           |
| Sponsor lists           | simple; mostly crosslinks                                   | existing                                | scraped                        | API; browsing                 |
| Sponsor lists history   | historical                                                  | existing                                | derived from wayback machine   | visualisations; API           |
| Platform crosswalk      | complex; technical                                          | existing                                | "derived, but checked"         | API                           |
| Hosted projects         | simple; mostly crosslinks to websites                       | needs building out for more data        | derived                        | browsing; API                 |
| Propublica 990 tax data | complex; financial                                          | existing                                | downloaded from trusted source | visualisations; API           |
| IRS 990 tax data        | complex; financial                                          | existing                                | downloaded from trusted source | visualisations; API           |
| 990 tax data history    | historical                                                  | partly existing                         | downloaded from trusted source | visualisations; API           |
| Foundation Budgets      | complex; financial - future dataset                         | future work by scraping annual reports  | scraped; estimated             | visualisations; API           |
| Leadership              | complex; people; listings of foundation boards and officers | future work by scraping websites        | scraped and checked            | browsing; visualisations      |
| Leadership history      | historical                                                  | future work by scraping wayback machine | derived from wayback machine   | visualisations; API           |
| Non-US Tax data         | complex; financial                                          | future work by parsing tax sites        | downloaded from trusted source | visualisations; API           |

## Next Step

Propose one or more URL naming schemes we can use consistently, and explain the advantages or disadvantages based on our project goals.

## Summary

- **Recommended: one dataset-first pattern for both audiences.** Every dataset gets a
  short plural name (`foundations`, `sponsor-lists`, `tax-filings`) and every record a
  stable key, usually the foundation `identifier`. People read
  `/{dataset}/{id}`; tools read `/api/v2/{dataset}/{id}.json`. Drop `/api/v2` and the
  extension from a data URL and you get the page about the same thing.
- **New work goes under `/api/v2/`** (decision 1). `/foundations/<id>`, the
  `_foundations/` files and their raw GitHub URLs, `_foundations/list.json`,
  `/openapi/v1/` and `/history/sponsorships/` all keep their current URLs, so `v1`
  stays the name of the original raw-GitHub API. The crosswalk exports, published only
  days earlier, move from `/api/v1/crosswalk/` to `/api/v2/crosswalk/`.
- **Discovery uses existing standards, not a custom API.** A DCAT catalog lists every
  dataset, each dataset page carries Schema.org `Dataset` markup (what Google Dataset
  Search reads), each record page links to its JSON with `rel="alternate"`, and the
  OpenAPI file describes the static paths on the site instead of raw GitHub.
- **Source files stay as they are.** Maintainers keep editing Markdown with YAML front
  matter, JSON and CSV in git. The `/api/v2/` files are generated from them, either at
  site build time or by export tools, so reviewers never read a second copy.

## What is published today

Built locally from `main` at `a699fdc` (2026-11-02) with `jekyll build`; GitHub Pages
serves `x.html` at `/x`.

| Kind | Published URLs | Notes |
| --- | --- | --- |
| Record pages | `/foundations/<id>` (89), `/sponsorships/<id>` (39), `/sponsors/<id>` (36), `/entities/<id>` (1), `/reports/<id>` (1) | Collections, `permalink: /:collection/:path` |
| Listing and docs pages | `/listing` (foundations), `/sponsors`, `/sponsorships`, `/entities`, `/reports`, `/projects`, `/fdnmodel`, `/crosswalk`, `/crosswalk-files`, `/taxes`, `/budgets`, `/data`, `/openapi` | Flat `_pages/` permalinks; foundations' list is not at `/foundations` |
| Per-foundation project pages | `/projects-asf`, `/projects-numfocus`, `/projects-processingfoundation`, `/projects-sfc`, `/projects-spi` | Hyphenated, not `/projects/<id>` |
| Machine data on the site | `/api/v1/crosswalk/<id>.json`, `context.jsonld`, `vocab.jsonld`, `stewards.jsonl`; `/history/sponsorships/<id>.json`; `/foundations/list.json`; `/openapi/v1/openapi.yaml`, `foundation-schema.yaml` | Only the crosswalk is JSON-LD with a license in the file |
| Machine data on raw GitHub only | `_foundations/<id>.md`, `_data/sponsorships/*.json`, `_data/p990/<ein>.json`, `_data/projects-*.csv`, every `_data/*-schema.json` | Jekyll never publishes `_` directories. `openapi.yaml` points its server at `raw.githubusercontent.com/.../main/` |
| Incidental | `/AGENTS.md`, `/assets/ruby/*.rb`, `/assets/python/...`, `/REUSE.toml` | Published because nothing excludes them; not part of this proposal |

Things worth fixing whatever scheme we pick:

1. A researcher can't get one foundation as JSON from the site; they parse YAML front
   matter from raw GitHub, which ties them to our directory layout and branch name.
2. `/foundations/list.json` is published, but the OpenAPI file names
   `/_foundations/list.json` on raw GitHub instead.
3. Taxes are stored by EIN (`_data/p990/<ein>.json`) while everything else uses the
   foundation `identifier`.
4. The crosswalk export already uses `https://fossfoundation.info/foundations/asf` as the
   `@id` of the foundation. That is a good pattern (the page URL names the
   organization) and every other export should do the same.
5. There is no catalog: nothing tells a crawler or a data tool which datasets exist,
   their licenses, or where their files are.

## Constraints from the prompt and AGENTS.md

- Don't change the `_foundations/` dataset or its existing URLs.
- Keep data in its current source formats in git, reviewable by hand.
- The site is static (GitHub Pages, built by Actions). There is no server, so no content
  negotiation, no query parameters, and no HTTP redirects. A format is chosen by file
  extension, and a moved page can only leave a small stub page behind.
- Prefer Schema.org, Dublin Core, DCAT and other common standards; datasets are
  CC0-1.0; no new dependencies without approval.
- Identifiers are stable; external ids live in their own fields.

## Three schemes compared

### A. Dataset-first (recommended)

Each dataset is a top-level collection, keyed by its own record id.

```text
/{dataset}/{id}                      page for people
/api/v2/{dataset}/{id}.json          the same record as JSON-LD
/api/v2/{dataset}/index.json         the dataset: metadata plus the list of records
/api/v2/{dataset}/all.jsonl          every record, one per line (bulk)
/api/v2/{dataset}/all.csv            flat datasets only, with CSVW metadata
```

- **For people:** the path reads as "a foundation called asf", "the sponsorships of
  asf". It matches what `/foundations/`, `/sponsors/`, `/sponsorships/` and `/entities/`
  already do, so most existing pages already follow it.
- **For researchers:** one rule covers every dataset, so a script that loads one dataset
  loads them all. Bulk files make loading a whole dataset one request. It is the layout
  that ecosyste.ms (`/api/v1/{collection}/{id}`) and most REST guides use.
- **For maintainers:** each dataset is generated independently; adding a dataset adds a
  directory, not a new rule.
- **Cost:** per-foundation facets (taxes, budgets, sponsor lists) live in separate
  datasets, so seeing everything about one foundation takes several requests. The
  foundation record links to each of them to make up for that.

### B. Organization-first (nested REST)

```text
/foundations/{id}/sponsorships
/api/v2/foundations/{id}/tax-filings/us.json
```

- Good for someone exploring one foundation, and it reads naturally.
- Poor for researchers, who mostly want one facet across all foundations. Datasets not
  keyed by a foundation (sponsors, entities, people) need a second pattern anyway.
- Would move the existing `/sponsorships/<id>` pages, and nests new paths under the
  `/foundations/` URLs we promised not to disturb.

### C. Keep raw GitHub as the API (today)

- No work, and every source file is already reachable.
- Ties researchers to `_` directory names, the `main` branch and file formats (YAML in
  Markdown) that we may want to change; GitHub can rate-limit or change those URLs; the
  site itself has nothing a crawler or catalog tool can discover; licenses aren't in the
  files.

Recommendation: **A**, while keeping raw GitHub URLs working and documenting them as
"source files" rather than the API.

## Recommended scheme in detail

### Naming rules

1. **Dataset names** are lowercase, plural nouns joined by hyphens: `foundations`,
   `sponsor-lists`, `tax-filings`. Mass nouns where a plural reads badly stay singular:
   `crosswalk` (already published), `leadership`.
2. **History is its own dataset**, named `<dataset>-history`, because it has a different
   source, accuracy and update rhythm (as the prompt's table already treats it). The one
   exception is a dataset whose records are already a time series, such as tax filings,
   which list every filing year.
3. **Record ids** are the dataset's `identifier`. Datasets about a foundation use the
   `_foundations` identifier, never a second key such as an EIN; external ids go inside
   the record (`taxID`, `leiCode`, `wikidataId`). Ids keep the existing pattern
   (lowercase letters, digits, underscore: `lpi_org`, `raspberrypi2`).
4. **Reserved file names** in each `/api/v2/{dataset}/`: `index`, `all`, `context`,
   `vocab`, `schema`. No record id may use one; the existing schema tests can check this.
5. **One version segment.** `v2` is the version of the URL layout and file shapes, not of
   the data. `v1` is the original API described by `/openapi/v1/` (raw GitHub paths and
   YAML front matter), which stays as it is. Only a later incompatible change to paths
   or shapes would add `/api/v3/`, and `v2` files would stay published.
6. **Format by extension:** `.json` for one record (JSON-LD, readable as plain JSON),
   `.jsonl` for bulk, `.csv` for flat tables, `.jsonld` for contexts, vocabularies and
   the catalog, `.yaml` for OpenAPI.
7. **No trailing slash on documents;** directories end with `/`.
8. **One URL names each thing.** The page URL (`https://fossfoundation.info/foundations/asf`)
   is the `@id` of the organization in every export, as the crosswalk already does. Data
   files describe that `@id`; they are not separate things.

### Every dataset under the scheme

Bold paths are new; everything else already exists and stays.

| Dataset | Name | Record key | Page for people | Data for tools |
| --- | --- | --- | --- | --- |
| Foundations | `foundations` | foundation id | `/foundations/asf` | **`/api/v2/foundations/asf.json`**; source `_foundations/asf.md` and `/foundations/list.json` unchanged |
| Entities | `entities` | entity id | `/entities/cncf` | **`/api/v2/entities/cncf.json`** |
| Sponsors | `sponsors` | sponsor id | `/sponsors/google` | **`/api/v2/sponsors/google.json`** |
| Sponsorships | `sponsorships` | foundation id | `/sponsorships/asf` | **`/api/v2/sponsorships/asf.json`** |
| Sponsor lists | `sponsor-lists` | foundation id | section of `/sponsorships/asf` | **`/api/v2/sponsor-lists/asf.json`** |
| Sponsor lists history | `sponsor-lists-history` | foundation id | `/sponsorships/asf#history` | **`/api/v2/sponsor-lists-history/asf.json`**; `/history/sponsorships/asf.json` kept |
| Platform crosswalk | `crosswalk` | foundation id | `/crosswalk` (docs) | **`/api/v2/crosswalk/asf.json`**, moved from `/api/v1/crosswalk/` (decision 2) |
| Hosted projects | `projects` | foundation id | **`/projects/asf`** (stub left at `/projects-asf`) | **`/api/v2/projects/asf.json`**, **`/api/v2/projects/all.csv`** |
| US 990 (ProPublica and IRS) | `tax-filings` | jurisdiction + foundation id | `/foundations/asf#taxes` | **`/api/v2/tax-filings/us/asf.json`** |
| 990 history | (same) | | | the filings list inside each record is the history |
| Non-US tax data | `tax-filings` | jurisdiction + foundation id | `/foundations/<id>#taxes` | **`/api/v2/tax-filings/gb/<id>.json`** (ISO 3166 code) |
| Budgets | `budgets` | foundation id | `/foundations/asf#budgets` | **`/api/v2/budgets/asf.json`** |
| Leadership | `leadership` | foundation id | **`/leadership/asf`** | **`/api/v2/leadership/asf.json`** |
| Leadership history | `leadership-history` | foundation id | section of `/leadership/asf` | **`/api/v2/leadership-history/asf.json`** |

Where a dataset is mostly used for visualisations or the API (taxes, budgets, sponsor
lists), the scheme gives it no page of its own; it appears as an anchored section of the
foundation or sponsorship page, and the anchor (`#taxes`, `#history`) is part of the
naming standard so it can be cited. Datasets used for browsing get their own pages.

ProPublica and IRS data both describe US 990 filings, so the proposal keeps them in one
`tax-filings/us` dataset and records the source of each filing inside the record
(`dcterms:source`) rather than in the URL. That is open question 3.

### Shared files

| URL | What | Standard |
| --- | --- | --- |
| **`/api/v2/catalog.jsonld`** | Every dataset, with title, description, license, publisher, update frequency, schema, page and download links | [DCAT 3](https://www.w3.org/TR/vocab-dcat-3/) with Schema.org `DataCatalog` terms |
| **`/api/v2/{dataset}/index.json`** | One dataset: its DCAT `Dataset` record plus the list of record ids and URLs. Replaces the role of `list.json` for new datasets | DCAT, Schema.org `Dataset` |
| **`/api/v2/context.jsonld`** | One JSON-LD context for all datasets; the crosswalk keeps its own context in `/api/v2/crosswalk/` until the two are merged | [JSON-LD 1.1](https://www.w3.org/TR/json-ld11/) |
| **`/api/v2/vocab.jsonld`** | Our own `fdn:` terms, where no standard term fits | RDFS |
| **`/api/v2/schemas/{dataset}.schema.json`** | Published copies of `_data/*-schema.json`, with matching `$id` URLs so validators can resolve them | JSON Schema |
| **`/api/v2/openapi.yaml`** | OpenAPI that lists the static paths above, with `servers: https://fossfoundation.info/api/v2`. `/openapi/v1/openapi.yaml` stays as the v1 description | [OpenAPI 3.1](https://spec.openapis.org/oas/v3.1.0) |
| **`/api/v2/{dataset}/all.csv-metadata.json`** | Column descriptions for CSV files; tools find it by this exact name | [CSV on the Web](https://www.w3.org/TR/tabular-data-primer/) |

### How people and tools find the data

- **Each record page** adds
  `<link rel="alternate" type="application/ld+json" href="/api/v2/foundations/asf.json">`
  in its `<head>` and a visible "Data (JSON)" link, so a person or crawler on any page
  can get the machine version.
- **Each dataset's docs page** (`/fdnmodel`, `/sponsors`, `/crosswalk`, `/taxes`…)
  embeds a Schema.org `Dataset` block with license and download links. This is what
  [Google Dataset Search](https://developers.google.com/search/docs/appearance/structured-data/dataset)
  and similar indexes read.
- **`/data`** embeds the catalog as Schema.org `DataCatalog`, and links to
  `/api/v2/catalog.jsonld` for DCAT harvesters (the format CKAN, data.europa.eu and
  other open data portals import).
- **Every exported file** states its `license` (CC0-1.0), `dateModified`, and the
  `isBasedOn` source file in git, so a downloaded file cites itself.
- **Citation:** the existing advice (page or file URL, access date, git commit) stays.
  A `CITATION.cff`, or dated releases archived with a DOI, could come later; that is
  open question 6.

### Pages for people

- Dataset pages follow `/{dataset}` (docs and listing) and `/{dataset}/{id}` (record),
  as `/sponsors` and `/sponsors/google` already do.
- **Foundations** keep `/foundations/<id>` and `/listing`. Adding a `/foundations` page
  (listing plus a pointer to `/fdnmodel`) would make the top of the URL tree readable
  without changing any foundation URL; that is open question 4.
- **Hosted projects** move from `/projects-asf` to `/projects/asf`, with a one-line stub
  page left at each old URL (a `<meta http-equiv="refresh">` plus `rel="canonical"`),
  which needs no new plugin.
- Docs pages keep their current names (`/fdnmodel`, `/taxes`, `/budgets`); only new
  pages follow the dataset names.

### How the files are produced

The `/api/v2/` files are outputs, never edited by hand, and the sources stay where they
are. Two ways to produce them, both already used in this repository:

1. **At site build time**, by a small Jekyll generator in `_plugins/` (plain Ruby, no new
   gem). Good for straight conversions of hand-edited records (foundations, entities,
   sponsors, sponsorships): the output can never drift from the source, and nothing
   generated is committed. The Pages workflow already runs custom plugins
   (`money_filter.rb`).
2. **By an export tool that commits its output**, as `fdncrosswalk export` does. Good for
   outputs that involve computation or history (crosswalk confidence, sponsor lists,
   tax filings), so reviewers see changes in the diff.

Recommendation: 1 for record conversions, 2 for computed data (open question 5).

## Suggested order of work

Each step is its own small PR, after the decisions below.

1. Move the crosswalk exports to `/api/v2/crosswalk/`, then delete `/api/v1/crosswalk/`
   in its own PR (decision 2).
2. Record the naming rules on `/data` and in `AGENTS.md`; add the reserved-names and
   id-pattern checks to existing tests.
3. `/api/v2/foundations/` (records, `index.json`, `all.jsonl`), with `rel="alternate"`
   links on foundation pages and the shared `context.jsonld`.
4. `/api/v2/catalog.jsonld` and the Schema.org `Dataset` blocks on dataset pages.
5. Point `openapi.yaml` at the site, and publish the schemas under `/api/v2/schemas/`.
6. The other existing datasets: sponsors, sponsorships, entities, sponsor lists and
   history, tax filings, projects (with the `/projects/<id>` move).
7. New datasets (budgets, leadership, non-US taxes) start in this layout.

## Open questions

1. **Scheme.** Adopt scheme A (dataset-first), with raw GitHub kept as "source files"? **SC:** Yes, agreed.
2. **History naming.** Separate `<dataset>-history` datasets (recommended), or a
   `history.json` file under each record (`/api/v2/sponsor-lists/asf/history.json`)?
   Either way `/history/sponsorships/` stays published. **SC:** Use separate `<dataset>-history` naming.
3. **Tax data.** One `tax-filings/{jurisdiction}/` dataset keyed by foundation id, with
   ProPublica and IRS as sources inside the record (recommended), or separate
   `propublica-990` and `irs-990` datasets? **SC:** Use separate datasets because these are subtly different kinds of data; most researchers may only need one of these sets.
4. **A `/foundations` page.** Add one (listing plus link to `/fdnmodel`), keeping
   `/listing`? **SC:** Yes, add the `/foundations` listing page.
5. **Generation.** Jekyll generator for record conversions plus committed exports for
   computed data (recommended), or committed exports for everything? **SC:** Yes, agreed: keep Jekyll generator for the human focused parts of our published website; use committed exports as recommended for other data.  
6. **Citation metadata.** Add `CITATION.cff` and DOIs for dated releases now, or later? **SC:** Add later; make this an Open Question For Maintainers at the end of this work. 
7. **`fdn:` namespace.** It is `https://fossfoundation.info/crosswalk#` today. Keep it for
   all datasets (stable, but oddly named), or start
   `https://fossfoundation.info/vocab#` for new terms and keep the crosswalk terms as
   they are? **SC:** Add a new vocab for all work going forward; the `fdn` name is a historical accident and is not a great namespace, because our focus is larger than just the foundations themselves.  We also need to add (as a future task; not this task) a Glossary of common terms on our site for human readers; much or all of the Glossary can probably be generated from selected key terms in our schemas. 
8. ~~**Moving the OpenAPI file.**~~ Answered by decision 1: the new spec is
   `/api/v2/openapi.yaml`, and `/openapi/v1/` stays as the description of v1.

## Decisions

1. **New work uses `/api/v2/`** (Shane, 2026-11-02). `/openapi/v1/` stays for
   historical compatibility as the description of the original raw-GitHub API, and the
   new site-hosted structure is clearly v2 going forward.
2. **The crosswalk moves to `/api/v2/crosswalk/`** (Shane, 2026-11-02). Its exports are
   new and probably unused, so the tool and docs move to v2 and `/api/v1/crosswalk/` is
   deleted, in a separate PR so the deletion can be tracked on its own.
