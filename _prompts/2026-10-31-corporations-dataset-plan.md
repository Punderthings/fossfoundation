<!-- SPDX-License-Identifier: Apache-2.0 -->
# Plan a corporations sponsor dataset

2026-10-31 · Shane Curcuru, with Claude

Status: decided; steps 0 (#83) and 1–4 implemented (#84); step 5 (exports) not started

## Prompt

> Let's add a new dataset that is a selected set of key corporations that commonly
> sponsor FOSS foundations as "corporations" as a working dataset title. This only
> includes corporations (or other legal entities) that sponsor and donate funds to
> multiple FOSS foundations, and the selection criteria would be partly based on how
> important that company (a sponsor) is within the open source software ecosystem. Our
> focus is on non-profit foundations, and we don't want to have to maintain fields or
> data that is easily available from other standards-based or broadly-used free and
> accurate information sources online. So the actual record we store for Google as a
> corporation, for example, might only include an identifier (for our site), a corporate
> lookup (for online corporation sources), common name, URL, and possibly some specific
> URLs to FOSS-specific pages like any open source policy, Open Source Program Office, or
> the like.
>
> Begin planning how to add this dataset to the site with these three tasks; propose if
> there are other major research tasks that we should do as well.
>
> * Review all datasets and schemas in fossfoundations and make a list of all places that
>   any field points to a sponsor corporation. Suggest any improvements or normalizations
>   to how we store the identifier or pointer to a corporation in different datasets, so
>   the way we express the relationship between a corporation and one of our datapoints
>   is consistent.
> * Review the top freely accessible online web services that provide structured and
>   reliable metadata about US corporations, like https://opencorporates.com/ ,
>   https://entitysearch.us/about/ , https://www.sec.gov/edgar/search/ , and the linked
>   services from https://library.doc.gov/company/research and suggest identifiers that
>   are commonly used and that we could store in our corporation record. Suggest the top
>   two or three corporate metadata information sources, focusing on corporate
>   organization structure and company leadership listings that are verifiable.
>   IMPORTANT: review the license and web scraping access policies of each site, and note
>   any technical issues with scraping, and any licensing issues with data from the site
>   that would not be compatible with our permissive Apache-2.0 license.
> * Propose a corporation schema that stores sufficient data in our repository so we can
>   tie together sponsors across foundations or time, and provides corporate lookup
>   identifiers that users can follow to discover more structured data about
>   corporations.

## Summary

- **Today the sponsor "identifier" is a web domain.** Every sponsor pointer in the
  repository, hand-edited or generated, is a registrable domain such as `google.com`,
  normalized by `host_aliases.json`. That works well as the *observed* value and should
  stay. The new dataset adds one resolution layer: each corporation record lists the
  domains that belong to it, so any domain in any dataset (current or history) resolves
  to a corporation `identifier` without rewriting existing files.
- **Store lookups, not facts others maintain.** Recommended lookup identifiers:
  `wikidataId` (already used for foundations and `commercial.csv`), `leiCode` (GLEIF
  Legal Entity Identifier), and `cik` (SEC EDGAR Central Index Key), plus `sameAs` URLs
  for registries we may only link to (OpenCorporates, UK Companies House, state
  registries).
- **Top sources for structure and leadership:** GLEIF (CC0, parent/child
  relationships), SEC EDGAR (US public information, subsidiaries and officers in
  filings), and Wikidata (CC0 hub that links all the other identifiers). UK Companies
  House is a strong fourth for UK companies. OpenCorporates, entitysearch.us, Delaware's
  ICIS search, and the subscription services on the Commerce Library page are not
  usable as data sources for an Apache-2.0/CC0 repository; at most we link to them.
- **Selection is measurable from our own data.** Counting distinct legal entities (the
  Linux Foundation and its directed funds count once), 36 sponsor domains currently
  sponsor 3 or more foundations, and 78 have done so at some time in the history files.
  That is a manageable first dataset.

## Task 1: everywhere a field points to a sponsor

### Inventory

| Where | Field | What it holds today | Edited by |
| --- | --- | --- | --- |
| [`_sponsorships/<id>.md`](../_sponsorships/) | `levels.<level>.sponsors[]` (static lists, with `staticmap`) | Domains, e.g. `google.com` in [`osi.md`](../_sponsorships/osi.md) | hand |
| [`_sponsorships/<id>.md`](../_sponsorships/) | `sponsormap` (and a disabled `xsponsormap` in [`lf.md`](../_sponsorships/lf.md)) | Path to a source-label → domain map file | hand |
| [`_data/fsfe_map.json`](../_data/fsfe_map.json), [`kde_map.json`](../_data/kde_map.json), [`lf_map.json`](../_data/lf_map.json), [`openstack_map.json`](../_data/openstack_map.json), [`python_map.json`](../_data/python_map.json) | keys → values | Each foundation's own label, slug, or profile path → domain, e.g. `"oracle-america-inc": "oracle.com"` | hand |
| [`_data/host_aliases.json`](../_data/host_aliases.json) | `aliases` | Hostname / domain / brand TLD → canonical domain, e.g. `facebook.com` → `meta.com`. Policy: merge renames and brand domains, keep separately run subsidiaries separate (`github.com` is not `microsoft.com`). This is the de facto company identity today. | hand |
| [`_data/sponsorships/<id>.json`](../_data/sponsorships/) | `<level>[]` | Domains seen at the last scrape | generated |
| [`_data/sponsorships/org-funding.json`](../_data/sponsorships/org-funding.json) | `sponsors` | Domain → estimated USD across all foundations (2,950 domains) | generated |
| [`_data/sponsorships/sponsor-counts.json`, `sponsor-history.json`, `sponsor-income.json`](../_data/sponsorships/) | — | Per-foundation counts and estimates only; no sponsor pointers | generated |
| [`history/sponsorships/<id>.json`](../history/sponsorships/) | `spans[].sponsor` | Domain, with `level`, `firstSeen`, `lastSeen` (7,382 distinct domains) | generated |
| [`_data/allsponsorships.json`](../_data/allsponsorships.json) | `<org>.<level>[]` | Early-2024 domains, partly un-normalized (`aws.amazon.com`, `facebook.com`); input to `sponsor_utils.rb --backfill-git` | legacy input |
| [`_foundations/<id>.md`](../_foundations/) | `sponsorList` | Mostly empty (63 of 90), a few URLs, and one free-text name list ([`osgeo.md`](../_foundations/osgeo.md)) | hand |
| [`_foundations/<id>.md`](../_foundations/) | `funding` | Free text categories (`sponsors, donations`); no pointer | hand |
| [`_data/commercial.csv`](../_data/commercial.csv) | `identifier`, `legalName`, `website`, `wikidataId` | Five companies often confused with FOSS projects (Red Hat, Docker, Mozilla Corp…). Not sponsors by definition, but the same kind of record. | hand |
| [`_data/crosswalk/<id>.json`](../_data/crosswalk/) | `person.memberOf` | Organization identifier for an attestor's role; defaults to the foundation | hand |
| Leadership plan, PR #58 (not merged) | `affiliation` | Proposed: a person's employer during a term, "as an `_entities` id or a company ID shared with the sponsorship data" | proposed |
| [`_includes/foundation-top-sponsors.html`](../_includes/foundation-top-sponsors.html) | — | Displays domains, linking `https://<domain>` | templates |

Not sponsor pointers: `_entities/` (unincorporated projects such as CNCF),
`projects-*.csv` `parentOrganization` (points to a foundation), `_data/p990/` and
`_data/taxes/` (foundations' own filings), `_data/research/drupal-credits.csv`
(percentages only).

### Problems found

1. **No company identity beyond a domain.** Domain changes (`facebook.com` → `meta.com`)
   are handled by aliases, but there is nowhere to record that `vmware.com` became part
   of Broadcom, that `github.com` is owned by Microsoft, or that `google.org` (the
   philanthropy arm) and `google.com` are related but distinct. Rollups by parent
   company are impossible.
2. **Renames that aliases miss.** History shows `blockchaintp.com` and `btp.works`
   each at 6 foundations with no alias between them, which looks like one company
   counted twice. A corporation record listing both domains fixes this without editing
   history.
3. **Free-text sponsor names in `sponsorList`.** OSGeo's list of names can't be joined
   to anything.
4. **Undocumented keys.** `levels.<level>.sponsors` (static sponsor lists) is not in
   `sponsorshiplevels-schema.json`, and `comment` and `xsponsormap` are not in
   `sponsorships-schema.json`. Not part of this plan's change; noted for a separate fix.
5. **Shared identifier namespace is unchecked.** `crosswalk person.memberOf` and the
   proposed leadership `affiliation` would hold either a foundation id or a company id.
   Nothing guarantees that a new corporation id never equals a foundation id.

### Proposed normalizations

- **N1. Domain stays the observed value; `identifier` is the reference.** Generated data
  (`_data/sponsorships/`, `history/sponsorships/`) keeps recording the domain it saw,
  because that is the evidence. Anything that *refers to* a corporation in hand-edited
  data (leadership `affiliation`, crosswalk `memberOf`, a future parent link) uses the
  corporation `identifier`.
- **N2. One resolution rule.** `domain → host_aliases.json → canonical domain →
  corporation whose domains[] contains it`. Implement it once (a small function in the
  sponsor tools, later Python), and have `sponsor_reports.rb` add an optional
  `corporation` key next to `sponsor` in reports such as `org-funding.json`. History
  files are not rewritten.
- **N3. Consistency tests, no network.** (a) Every `domains[]` entry is already
  canonical under `host_aliases.json`; (b) no domain belongs to two corporations;
  (c) corporation identifiers don't collide with `_foundations` or `_entities`
  identifiers (one namespace for organizations on this site).
- **N4. Static lists and maps keep using domains.** `levels.*.sponsors[]` and the
  `*_map.json` files already map to domains; document `sponsors` in the levels schema
  (separate PR).
- **N5. Relationship field names follow Schema.org.** A corporation sponsors a
  foundation: Schema.org [`sponsor`](https://schema.org/sponsor) /
  [`funder`](https://schema.org/funder) on the foundation side. Ownership:
  [`parentOrganization`](https://schema.org/parentOrganization) /
  [`subOrganization`](https://schema.org/subOrganization). Employment:
  [`worksFor`](https://schema.org/worksFor) or an `OrganizationRole`, as the leadership
  plan proposes. JSON-LD exports use these terms.
- **N6. ~~`commercial.csv` shares the namespace.~~** Dropped: `commercial.csv` stays
  separate and is not used or referenced by this work (decision 4).

## Task 2: corporate metadata sources

All checks below were made on 2026-10-31 from each site's own terms page unless noted.
The sandbox could not reach gleif.org or sec.gov APIs directly, so no data was fetched,
only policy pages.

### Comparison

| Source | What it gives | Identifier | License / reuse | Automated access | Fit |
| --- | --- | --- | --- | --- | --- |
| [GLEIF LEI](https://www.gleif.org/en/meta/lei-data-terms-of-use) | Legal name, jurisdiction, registration authority id, and Level 2 direct and ultimate parent relationships | LEI (20 chars, ISO 17442); Schema.org [`leiCode`](https://schema.org/leiCode) | "The data available through the Access Service are provided under the CC0 licence." No attribution required; can't claim IP in LEIs or imply GLEIF endorsement. | Free API and bulk "golden copy" files, no key; access must go through GLEIF's service. | **Top pick for structure.** No leadership data. Covers only entities that have registered an LEI, so some smaller sponsors will have none. |
| [SEC EDGAR](https://www.sec.gov/os/accessing-edgar-data) | Filings of US public companies: 10-K (incl. Exhibit 21 subsidiaries list, executive officers), DEF 14A proxy (board), Forms 3/4 (insiders); JSON APIs on data.sec.gov; ticker↔CIK file | CIK (Central Index Key) | [sec.gov privacy page](https://www.sec.gov/privacy): "Information presented on sec.gov is considered public information and may be copied or further distributed … without the SEC's permission"; please cite the SEC. Compatible. | Max 10 requests/second; must declare a User-Agent with a contact address; "unclassified" bots not allowed. | **Top pick for verifiable leadership** of US public companies. Nothing for private companies (e.g. many smaller sponsors). |
| [Wikidata](https://www.wikidata.org/wiki/Wikidata:Licensing) | Hub linking LEI (P1278), CIK (P5531), PermID (P3347), OpenCorporates and registry ids, parent (P749), subsidiary (P355), owned by (P127), official website (P856), with dated qualifiers | Q-id; already our `wikidataId` | CC0 for structured data | Public SPARQL and API; polite User-Agent | **Top pick as the hub.** Crowd-edited, so treat as a lookup, and verify any fact we store against a primary source. |
| [UK Companies House](https://forum.companieshouse.gov.uk/t/is-data-provided-under-the-ocs/4513) | Officers, persons with significant control, filings, for UK companies | Company number | Companies House says it "imposes no rules or requirements on how the information on the public register is used"; users remain responsible for data protection law | Free API with key; 600 requests / 5 minutes (per a third-party summary, not verified on the official portal) | Good for UK sponsors. Officer data is personal data; see privacy note below. |
| [PermID (LSEG)](https://developers.lseg.com/en/api-catalog/open-perm-id/permid-record-matching-restful-api/documentation/overview-and-concepts/faq) | Organization ids, basic hierarchy | PermID | Basic data CC BY 4.0; extended fields CC NC 3.0 (non-commercial) | Lookup without key; search needs a token, 5,000 records per key | Optional identifier only. Storing the id is fine; don't copy extended fields (NC is incompatible). |
| [OpenCorporates](https://opencorporates.com/terms-of-use-2/) | Registry data for many jurisdictions | `<jurisdiction>/<company number>` in its URLs | Database is ODbL: share-alike plus mandatory "from OpenCorporates" link; non-share-alike licences are paid | Terms prohibit "Using any automated system (e.g. scraping) to extract data for any purpose other than search engine indexation"; API needs a key; free keys only for "Permitted Users" (e.g. academics) and are share-alike | **Link only.** ODbL share-alike is not compatible with publishing our data as CC0 / Apache-2.0, and scraping is prohibited. A URL in `sameAs` is fine. |
| [entitysearch.us](https://entitysearch.us/about/) | Guides to each state's business search; fee and deadline data | none for entities | Run by Startupsole LLC; "not an official business register"; [terms](https://entitysearch.us/terms/) forbid copying or aggregating content and "Systematically retrieve data … to create or compile a database" | No API | **Not a source.** Useful only as a guide to state registries. |
| [Delaware ICIS entity search](https://icis.corp.delaware.gov/Ecorp/EntitySearch/NameSearch.aspx) | Name, file number, formation date, registered agent; status costs money | Delaware file number | Public record, but the page "prohibits data mining" and warns "Use of automated tools in any form may result in the suspension of your access" | Manual only | **Manual lookup only.** Many US companies incorporate in Delaware, so the file number can be a hand-verified id, but it is not worth storing over LEI/CIK. |
| [SAM.gov Entity API](https://open.gsa.gov/api/entity-api) | Federal contractors: UEI, CAGE, legal name | UEI (replaced D-U-N-S in federal use) | Public tier only; corporate hierarchy is FOUO (not public) | Key required; 10 requests/day without a SAM role, 1,000 with one | Not recommended: no public hierarchy, tiny limits, only contractors. |
| Subscription services on the [Commerce Library page](https://library.doc.gov/company/research): D&B Hoovers / Investigate, Lexis, Nexis Diligence+, Bloomberg, Statista, Uniworld, Leadership Connect, EBSCO, ProQuest, FT, WSJ, ThomasNet | Company profiles, family trees, executives | D-U-N-S (proprietary), others | Licensed to the library's users; not redistributable | Not allowed | **Not usable.** The page's only free link is SEC EDGAR. Don't store D-U-N-S numbers even though Schema.org has [`duns`](https://schema.org/duns), since D&B controls them. |
| [OpenSanctions](https://www.opensanctions.org/datasets/permid) | Aggregated company and people data | — | CC BY-NC 4.0; businesses need a licence | — | Not usable (non-commercial). |

### Licensing notes for an Apache-2.0 / CC0 repository

- An identifier by itself (an LEI, a CIK, a registry number) is a fact, so storing one
  that we checked by hand is fine whichever site we saw it on. What the terms restrict
  is copying their *database* (OpenCorporates, entitysearch.us) or using automated
  tools (OpenCorporates, Delaware, SEC beyond its policy).
- Safe to copy facts from: GLEIF (CC0), Wikidata (CC0), SEC (public information, cite
  it), Companies House (no reuse rules, data protection still applies), PermID basic
  fields (CC BY 4.0, attribute it).
- Not safe to copy from: OpenCorporates (ODbL share-alike), PermID extended fields and
  OpenSanctions (non-commercial), entitysearch.us and all subscription services
  (proprietary).
- Following our "complement, don't copy" rule, the dataset stores ids and links; tools
  may look up GLEIF/SEC/Wikidata at use time rather than committing their data.

### Privacy note on leadership

Officer and board names from SEC proxies or Companies House are public, but they are
data about individual people. AGENTS.md requires a maintainer-approved data model before
we store any. This plan stores **no** corporate leadership in the corporations dataset;
it links to where leadership is published (see `leadershipurl` below and research task
R6).

## Task 3: proposed corporation schema (draft)

### Where it lives

- `_corporations/<identifier>.md`: a Jekyll collection, one file per corporation, like
  `_foundations/`. YAML front matter, `CC0-1.0`. No descriptive body text at first (it
  would need the fairness review we give foundation descriptions).
- `_data/corporations-schema.json`: JSON Schema with each field's Schema.org term.
- Later, generated exports `api/v1/corporations/` as JSON-LD and CSV (CC0), like the
  crosswalk exports.

### Fields

| Field | Required | Schema.org / standard | Meaning here |
| --- | --- | --- | --- |
| `identifier` | yes | [`identifier`](https://schema.org/identifier) | Our stable slug, `^[a-z0-9-]+$`, unique across foundations, entities and corporations. Never renamed. |
| `commonName` | yes | [`name`](https://schema.org/name) | Name in common use (Google, Red Hat). Same field name as `_foundations`. |
| `legalName` | no | [`legalName`](https://schema.org/legalName) | Exact legal name of the entity whose ids we store (e.g. the operating company that signs sponsorships, not always the listed parent). Taken from GLEIF or SEC. |
| `@type` / `entityType` | yes | [`Corporation`](https://schema.org/Corporation), [`NGO`](https://schema.org/NGO), [`GovernmentOrganization`](https://schema.org/GovernmentOrganization), [`EducationalOrganization`](https://schema.org/EducationalOrganization) | Covers the "other legal entities" that sponsor several foundations (corporate foundations such as Google.org, government funds, universities hosting mirrors). |
| `website` | yes | [`url`](https://schema.org/url) | Primary homepage. |
| `domains` | yes | none; related to `url` | **Join key to all sponsor data.** Canonical registrable domains (after `host_aliases.json`) that sponsor lists use for this organization; first is primary. |
| `wikidataId` | recommended | Wikidata Q-id, via [`sameAs`](https://schema.org/sameAs) in JSON-LD | Hub to every other identifier. Same field as `_foundations`. |
| `leiCode` | when one exists | [`leiCode`](https://schema.org/leiCode), ISO 17442 | GLEIF LEI of the `legalName` entity; follow it for parent/child structure. |
| `cik` | when one exists | SEC CIK; [`identifier`](https://schema.org/identifier) as a `PropertyValue` with `propertyID` `sec-cik` in JSON-LD | For US public companies; follow it for filings, subsidiaries, and officers. |
| `taxID` | for nonprofits only | [`taxID`](https://schema.org/taxID) | US EIN or other tax id, for sponsor foundations/NGOs, matching `_foundations`. |
| `sameAs` | no | [`sameAs`](https://schema.org/sameAs) | Registry page URLs we can only link to: OpenCorporates, Companies House, PermID, ROR (for universities). |
| `parentOrganization` | no | [`parentOrganization`](https://schema.org/parentOrganization) | List of `{identifier, startDate, endDate, source}` pointing to another corporation in this dataset, only when needed to roll up sponsors (e.g. GitHub → Microsoft). See open question 3. |
| `opensourceurl` | no | [`url`](https://schema.org/url) | The company's main open source landing page. |
| `ospourl` | no | [`url`](https://schema.org/url); TODO Group's OSPO definition | Its Open Source Program Office page, if it has one. |
| `policyurl` | no | [`publishingPrinciples`](https://schema.org/publishingPrinciples) | Published open source contribution or usage policy. |
| `leadershipurl` | no | [`url`](https://schema.org/url) | Company's own page listing executives or board, instead of storing names. |
| `sources` | yes | Dublin Core [`source`](http://purl.org/dc/terms/source) | List of `{url, observed, detail}` for every stored value, like crosswalk `evidence`. |
| `lastReviewed`, `reviewedBy` | yes | Dublin Core [`modified`](http://purl.org/dc/terms/modified) | Same meaning as in the crosswalk. |

Deliberately left out, because GLEIF, SEC, or Wikidata maintain them: addresses,
jurisdiction, founding date, employees, revenue, ticker, industry codes, subsidiaries
lists, officers.

### Example (values to be filled and verified when the record is created)

```yaml
# SPDX-License-Identifier: CC0-1.0
identifier: google
commonName: Google
legalName: <legal name from GLEIF>
entityType: Corporation
website: https://www.google.com/
domains:
  - google.com
wikidataId: <Q-id>
leiCode: <LEI of legalName>
cik: <CIK of the SEC filer, if we choose the listed parent; see open question 2>
sameAs:
  - <OpenCorporates URL>
opensourceurl: https://opensource.google/
ospourl: <OSPO page>
policyurl: <open source policy page>
sources:
  - url: <GLEIF record URL>
    observed: <date>
    detail: legalName and leiCode
lastReviewed: <date>
reviewedBy: <GitHub login>
```

### How it ties sponsors together

- **Across foundations:** every scraped domain resolves to one `identifier` (N2), so
  "foundations Microsoft sponsors" is a join, today and in history.
- **Across time:** history `spans[]` already have dates; `parentOrganization` with
  dates rolls acquisitions up correctly (Red Hat counted under IBM only after the
  acquisition date, for example).
- **Outwards:** `wikidataId`, `leiCode` and `cik` let a reader or tool fetch
  structure and leadership from the authoritative source.

## Proposed additional research tasks

- **R1. Selection criteria.** Turn "sponsors multiple foundations, important to the
  ecosystem" into a rule we can rerun. First cut from our data: sponsors at 3+
  distinct legal entities currently (36 domains) or historically (78), counting the LF
  and its directed funds once, plus the top 50 by estimated funding. Then decide on
  ecosystem-importance signals (e.g. OSPO existence, TODO Group membership, ecosyste.ms
  repository owner data) and whether in-kind-only sponsors count.
- **R2. Sponsor identity audit.** Review the top ~150 domains for splits and merges the
  aliases miss (`blockchaintp.com`/`btp.works`, `google.org` vs `google.com`,
  `huaweicloud.com` vs `huawei.com`, `alibabacloud.com`, regional subsidiaries) and
  decide which belong in `host_aliases.json` versus `domains[]` versus a separate
  corporation.
- **R3. Mergers and acquisitions timeline** for the selected set (dates from SEC 8-K
  filings or GLEIF relationship start dates), needed before parent rollups in history
  reports.
- **R4. FOSS-specific corporate pages.** Survey which selected companies publish an OSPO
  page, open source policy, or contribution guidelines, and whether TODO Group or
  OpenSSF publish a reusable, openly licensed list we can link instead.
- **R5. Other funding channels.** How corporate money also reaches projects through
  GitHub Sponsors, Open Collective, Tidelift-style intermediaries, and corporate
  foundations (Google.org, Bloomberg Philanthropies) and government funds (Sovereign
  Tech Agency); ecosyste.ms's sponsors index is the obvious place to complement (via a
  polite email `mailto=`, as with our other ecosyste.ms use).
- **R6. Corporate people and affiliations.** Coordinate with the leadership plan
  (PR #58): employer `affiliation` should point to a corporation `identifier`. Decide,
  with a maintainer, whether we ever store any corporate officers or only link to
  them.
- **R7. Publishing and discovery.** JSON-LD (Schema.org `Corporation`) and CSV exports,
  REUSE entries, a `/corporations` page, and whether to contribute missing LEI/CIK links
  back to Wikidata.

## Implementation steps (after decisions)

0. Separate PR first (decision 6): document the undocumented keys in the existing
   sponsorship schemas: `levels.<level>.sponsors` in `sponsorshiplevels-schema.json`,
   and `comment` in `sponsorships-schema.json`. The N2 `corporation` key in
   `org-funding.json` has no schema file today and depends on corporation records, so
   it ships with step 3.
1. Schema `_data/corporations-schema.json`, `_corporations/` collection config, layout
   and a list page; 3–5 hand-verified records.
2. Resolution function and the consistency tests (N2, N3), no network.
3. `corporation` key in `org-funding.json` and a "sponsors across foundations" report.
4. Fill the rest of the selected set from R1, each with sources.
5. Exports and documentation (R7).

## Open questions

1. **Dataset name and location.** `_corporations/` collection with `corporations` as the
   name, even though some records are NGOs or government bodies? (Recommended: yes,
   keep the working title; `entityType` carries the distinction.) SC: Agreed, and use entityType.
2. **Which legal entity a record represents.** The brand-level operating company that
   signs sponsorships (Google LLC) or the listed parent (Alphabet Inc.)? (Recommended:
   one record per brand that appears in sponsor lists, with `legalName`/`leiCode` for
   that operating entity, and the listed parent as its own record only when two or more
   sponsor brands roll up to it.) SC: Agreed; while more detailed corporate ownership research is interesting, our focus is on the specific brands that sponsor FOSS Foundations, and are known as 'Google' colloquially.
3. **Store parent links ourselves or derive them?** Storing `parentOrganization` with
   dates is a small amount of data that GLEIF and Wikidata also hold. (Recommended:
   store it only for corporations in our dataset, with a source, because history
   rollups need it offline and reproducibly.) SC: Agreed, history analysis of sponsors will be important as we improve this site.
4. **`commercial.csv`.** Fold its five companies into `_corporations/` with a flag, or
   keep it separate and only share identifiers? (Recommended: keep separate for now,
   share the namespace.) SC: Agreed, keep separate; do not use or reference commercial.csv going forward; it was only a temporary idea that we are likely to remove.
5. **Selection threshold.** 3+ distinct legal entities, or another rule (R1)? SC: Agreed
6. **Change existing schemas?** N2 adds a `corporation` key to a generated report, and
   N4 documents `sponsors` in the levels schema. Both are schema changes that need
   approval; do them in this dataset's PR or separately? SC: Make those other schema changes as a separate PR first, as a way to improve those schemas. Then do PR(s) for this work.
7. **OSGeo `sponsorList` free text.** Replace with its sponsor URL and model OSGeo's
   sponsors as a sponsorship program instead? (Changing foundation data, so asking.) SC: No, leave OSGeo alone; we are only focusing on corporations and key sponsorships currently; we will work on OSGeo or other foundation data later.

Posted by Claude on behalf of @ShaneCurcuru and edited by SC

## Decisions

Answered by Shane Curcuru on 2026-10-31 in PR #82 (inline **SC:** notes above).

1. Use `_corporations/` and the working title "corporations"; `entityType` carries the
   kind of legal entity.
2. One record per brand that sponsors FOSS foundations (colloquially "Google"), with
   `legalName`/`leiCode` for that operating entity; a listed parent gets its own
   record only when two or more sponsor brands roll up to it. Deeper ownership research
   is out of scope.
3. Store dated `parentOrganization` links ourselves, with sources, for corporations in
   the dataset, because sponsor history analysis needs them.
4. Keep `commercial.csv` separate, and don't use or reference it going forward; it is
   likely to be removed.
5. Selection threshold: sponsors of 3 or more distinct legal entities (R1).
6. Make the existing-schema changes in a separate PR first, then PR(s) for this
   dataset.
7. Leave OSGeo's `sponsorList` alone; other foundation data is later work.

## Implementation notes

2026-11-01, PR #84 (steps 1–4), as asked by Shane: "Implement the plan for the corporations
dataset. Start your OSPO research with the TODO group listing".

- 36 records: every sponsor domain in current sponsor lists of 3+ distinct legal entities.
- `opensourceurl` comes from the [TODO Group OSPO Landscape](https://github.com/todogroup/ospolandscape)
  (Apache-2.0) at commit `2cb0f82`; entries whose URL was unclear (Huawei, Arm, Capital One,
  AMD Xilinx) were left out.
- `cik` comes from the SEC's `company_tickers.json`.
- `leiCode` and `legalName` come from the GLEIF API (`api.gleif.org/api/v1/lei-records`) for
  29 of the 36 records, each with a source pointing at its LEI record. The LEI is the
  operating entity behind the brand: the listed company where the brand is the company, or
  the operating subsidiary (Google LLC, GitHub Inc, Functional Software for Sentry). Check
  digits were verified (ISO 7064 mod 97). Meta's LEI is LAPSED (not renewed) but still
  identifies the entity. Left out because no single LEI clearly matched the brand: Red Hat
  (only Red Hat, LLC and country subsidiaries), SUSE (SUSE S.A. and country entities),
  JetBrains (JetBrains N.V. and JetBrains s.r.o.), Rackspace (two Rackspace Technology
  entities), Leaseweb (country entities only), GEICO (no record found), and OSU OSL (a
  university lab, not expected to have one).
- `wikidataId` is not filled. On 2026-11-01 Shane asked to re-check access: GLEIF's API
  answered through the agent's web fetch tool (not through `curl`, which the sandbox proxy
  blocks), while Wikidata (www, m., Special:EntityData, and the SPARQL endpoint) was refused
  by both. Wikidata ids remain a help-wanted task for someone with direct access.
- The `corporations` report section lives in `org-funding.json` (N2); history rollups by
  `parentOrganization` and the exports (step 5) are follow-ups.
