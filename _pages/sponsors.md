---
title: Sponsors
excerpt: Key sponsors that fund several FOSS foundations, with lookups to authoritative corporate data.
permalink: /sponsors
parent: Data Models
nav_order: 35
---

The **sponsors** dataset lists key sponsors that fund several FOSS foundations, so that sponsors can be tied together across foundations and over time. Each record is small on purpose. It holds our identifier, the web domains that join it to our [sponsor data](sponsorships), and lookup identifiers that lead to authoritative sources for everything else, such as corporate structure, filings, and leadership.

Records live in [`_sponsors/`](https://github.com/Punderthings/fossfoundation/tree/main/_sponsors), one file per organization. They are checked against [`sponsors-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsors-schema.json), which documents every field and the Schema.org term it maps to. The data is [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/). The plan and decisions behind it are in [`_prompts/2026-10-31-corporations-dataset-plan.md`](https://github.com/Punderthings/fossfoundation/blob/main/_prompts/2026-10-31-corporations-dataset-plan.md), which uses the dataset's earlier working title, "corporations".

## Listing

{% assign cp_report = site.data.sponsorships['org-funding'].sponsorRecords -%}
| Organization | Type | Sponsorship programs now | Open source site |
| --- | --- | --- | --- |
{% for sp in site.sponsors -%}
{%- assign cp_row = cp_report[sp.identifier] -%}
| [{{ sp.commonName }}](/sponsors/{{ sp.identifier }}) | {{ sp.entityType }} | {{ cp_row.foundations.size | default: 0 }} | {% if sp.opensourceurl %}[{{ sp.opensourceurl | remove: "https://" | remove: "http://" }}]({{ sp.opensourceurl }}){% endif %} |
{% endfor %}

## Selection criteria

A record is one **sponsoring brand**, the name that appears in sponsor lists (for example Google, not Alphabet). Its listed parent company gets a record of its own only when two or more sponsoring brands roll up to it.

The first set includes every sponsor that the current sponsor lists show at **3 or more distinct legal entities**. The Linux Foundation and its directed funds (CNCF, OpenSSF, and the others with `nonprofit: lf`) count as one entity. Organizations other than companies qualify too, so `entityType` records the kind of legal entity: `Corporation`, `NGO`, `GovernmentOrganization`, or `EducationalOrganization`.

Rarely, a sponsor is not a legal organization; some foundations list individual people as sponsors. This dataset records organizations only. Whether researchers would want individual sponsors classified differently is an open question for future research, recorded in the plan, and any data about people follows our privacy rules.

## What a record stores

- **`identifier`**: our stable id and file name. It shares one namespace with `_foundations` and `_entities`, and is never renamed or reused.
- **`commonName`**, **`entityType`**, **`website`**.
- **`domains`**: the canonical sponsor domains (after [`host_aliases.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/host_aliases.json)) that our sponsor lists and history use. This is the **join key**. Sponsor data keeps recording the domain it saw, and the domain resolves to a sponsor here, so history files never need rewriting.
- **Lookups**: `wikidataId`, `leiCode` (GLEIF), `cik` (SEC EDGAR), `taxID` (non-profits only), and `sameAs` links to registries we only link to.
- **`parentOrganization`**: the owner, with dates and a source, when the owner also has a record here. Sponsor history can then be rolled up by owner (GitHub under Microsoft from 2018-10-26, for example).
- **FOSS pages**: `opensourceurl`, `ospourl`, `policyurl`, and `leadershipurl`. We link to leadership pages instead of storing people's names.
- **`sources`**: where each stored value can be checked again, with the date it was checked; plus `lastReviewed` and `reviewedBy`.

We deliberately leave out facts that GLEIF, SEC EDGAR, or Wikidata maintain, such as addresses, founding dates, revenue, subsidiaries, and officers.

## Sources and licensing

- **Used for facts:** [GLEIF](https://www.gleif.org/en/meta/lei-data-terms-of-use) (CC0), [SEC EDGAR](https://www.sec.gov/privacy) (public information; the SEC asks for citation), [Wikidata](https://www.wikidata.org/wiki/Wikidata:Licensing) (CC0), and the [TODO Group OSPO Landscape](https://github.com/todogroup/ospolandscape) (Apache-2.0) for open source sites.
- **Linked only:** OpenCorporates, whose database is ODbL share-alike and whose terms prohibit scraping, and company registries such as Delaware's, which prohibit automated searches.
- **Not used:** subscription services (D&B, Lexis, Bloomberg) and non-commercial datasets (OpenSanctions, PermID extended fields).

The plan document has the full comparison.

## Tools

- `ruby assets/ruby/sponsors.rb --check` checks every record. Each identifier must match its file name and must not collide with a foundation or entity id. Each domain must be canonical and belong to only one sponsor, and every parent must have a record.
- `ruby assets/ruby/sponsor_reports.rb` writes a `sponsorRecords` section into [`org-funding.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsorships/org-funding.json). For each record it lists the foundations and levels that sponsor it now, and an estimate that uses the same rules as the per-sponsor estimates.

Run both from the repository root with `BUNDLE_GEMFILE=assets/ruby/Gemfile bundle exec`.

## Help wanted

- Add `wikidataId` for the records that don't have one yet, from Wikidata.
- Find `leiCode` and `legalName` for the records that don't have one yet, such as Red Hat, SUSE, and JetBrains, where several GLEIF entities could match the brand.
- Add `ospourl` and `policyurl` pages from each company's own site.
- Roll sponsor history up by `parentOrganization` in the history reports.
- Publish JSON-LD and CSV exports, as the crosswalk does.
