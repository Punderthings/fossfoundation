---
title: Data Philosophy
excerpt: Metadata standards and practices for this project.
layout: default
permalink: /data
parent: Data Models
nav_order: 1
---

This foundation directory curates metadata that is rigorously organized enough for academic research, and is easy enough to maintain by open source organizers.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

## What We Collect

We record non-profit FOSS organizations, the people who lead them, and how they are funded.  Data about code, packages, repositories, and similar technical details is left to [ecosyste.ms](https://ecosyste.ms/) and similar services, which we link to rather than copy.  Every fact should trace to a source we checked, preferably the organization's own website; see the [rules for data](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md#rules-for-data).

## Data Organization Philosophy

All data, basic instructions and explanations about the site, and basic visualizations or listings should be stored in human-editable formats, and should be served statically with minimal dependencies.  This ensures that maintenance issues don't break things, and that people with limited browsing clients can still participate.  Advanced features or larger data analysis tools should seek to minimize dependencies or any regular required maintenance.  Our data should also strive to be consistent and persistent.  This helps both casual users find the data, and helps researchers by keeping stable URLs and formats.

## Datasets

Each dataset has its own page, which documents its fields, schema, and tools.  *Hand-edited* datasets are maintained by people through pull requests; *generated* ones are produced by our tools from other data and are never edited by hand.

| Dataset | What it holds | Where it lives | Schema | Maintained |
| --- | --- | --- | --- | --- |
| [Foundations](fdnmodel) | One record per non-profit FOSS organization: legal identity, governance, policies, funding | [`_foundations/`](https://github.com/Punderthings/fossfoundation/tree/main/_foundations) | [`foundations-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) | hand-edited |
| [Entities](entities) | Self-organized projects that are not legal corporations, and typically use a fiscal host, such as CNCF | [`_entities/`](https://github.com/Punderthings/fossfoundation/tree/main/_entities) | work in progress | hand-edited |
| [Sponsors](sponsors) | Key sponsors that fund several foundations: the domains that join them to sponsor data, and lookup identifiers such as LEI, SEC CIK, and Wikidata | [`_sponsors/`](https://github.com/Punderthings/fossfoundation/tree/main/_sponsors) | [`sponsors-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsors-schema.json) | hand-edited |
| [Sponsorships](sponsorships) | Ordinal levels of recurring sponsorship programs, drawn from each organization's own prospectus | [`_sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/_sponsorships) | [`sponsorships-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsorships-schema.json) | hand-edited |
| [Sponsor lists and history](sponsorships) | Current sponsor lists, monthly history with provenance, and summary reports | [`_data/sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/sponsorships), [`history/sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/history/sponsorships) | described on [Sponsorship Models](sponsorships) | generated |
| [Platform crosswalk](crosswalk) | Which code host and package registry accounts belong to a foundation, with evidence | [`_data/crosswalk/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/crosswalk) | [`crosswalk-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk-schema.json) | hand-edited; its [JSON-LD exports](crosswalk#exports) in `api/v2/crosswalk/` are generated |
| [Hosted projects](projects) | Projects hosted by some foundations, for context | `_data/projects-<identifier>.csv` | CSV, with column names in the header row | scraped, then reviewed by hand |
| [Crosswalk evidence and attestations](crosswalk#evidence) | Why each crosswalk link is believed: the evidence items inside each crosswalk file, the [attestors](crosswalk#attestors) whose confirmations count, and [records of the people who confirmed links](crosswalk#people) | evidence in [`_data/crosswalk/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/crosswalk); [`_data/attestors.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestors.json); public person records in [`_data/attestations.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestations.json), private ones in the maintainers' private repository | [`crosswalk-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk-schema.json), [`attestors-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestors-schema.json), [`attestations-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestations-schema.json) | hand-edited; attestors by maintainers only; evidence with `fdncrosswalk attest`, person records with `fdncrosswalk add-person` |
| [ProPublica 990 tax data](taxes#propublica-990) | ProPublica Nonprofit Explorer's summary of IRS 990 filings for US foundations: about 70 totals per filing, a year or more after filing | [`_data/p990/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/p990) | ProPublica's format | generated (downloaded by [`foundation_reporter`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/foundation_reporter.rb)) |
| [IRS 990 tax data](taxes#irs-990) | Line-item detail parsed from the IRS's own 990 e-file XML, including recent years ProPublica has not parsed yet | not yet published here | [Frictionless Data](https://frictionlessdata.io/) package written by the tool | in progress: generated by [`foss990parser`](https://github.com/Punderthings/foss990parser) |
| [Budgets](budgets) | Planned: actual or estimated budget figures from organizations' own reports | not yet | not yet | planned |

**Entities** are self-organized and funded projects that are not legal corporations.  Key examples are CNCF (a division of the Linux Foundation) and Debian (with a documented governance and budget structure, but uses SPI as a fiscal host).

**US 990 tax data** comes from the IRS Form 990 that US nonprofits file each year, recorded from two different sources, so it is kept as two datasets.  **ProPublica 990** data quickly gives a solid financial overview of many US-based foundations; we host ProPublica's organizational 990 JSON as a convenience, and expect to keep its URLs permanently.  **IRS 990** data is parsed directly from the IRS's e-file XML, with much more detail and newer years, but in a different format with some subtly different values.  The [US 990 Taxes Model](taxes) explains both and how they differ; most researchers need only one of them.

**Crosswalk evidence** records why we believe each crosswalk link.  Most evidence is a public page anyone can check again; `human-attested` evidence is a confirmation that a trusted [attestor](crosswalk#attestors) got out of band from someone at the organization.  These attestations are given by volunteers and have not been legally reviewed to qualify as attestations under the EU Cyber Resilience Act or other legislation; see their [legal status](crosswalk#legal-status).  Records of those people are kept private by default, and are public only when the person agreed.

**Non-US Tax Data** Some countries post nonprofit financial data; most do not.  Our [`foundation_reporter`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/foundation_reporter.rb) tool can download UK Charity Commission data, stored as [`_data/taxes/uk-<charity number>.json`](https://github.com/Punderthings/fossfoundation/tree/main/_data/taxes), and we are **looking for help** in modeling foundations outside the US!

## Licensing

Our licensing philosophy is to allow maximal reuse by anyone, both for datasets hosted, website presentation, and any automated tools.

Code and prose are licensed under [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0).  New datasets and data exports, such as the [sponsors](sponsors) records, the public [attestation records](crosswalk#people), and the [crosswalk exports](crosswalk#exports), are [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/).  Existing data files are currently Apache-2.0.  Each file's license is declared following the [REUSE](https://reuse.software) specification in [`REUSE.toml`](https://github.com/Punderthings/fossfoundation/blob/main/REUSE.toml).

## Citing This Data

Please cite the page or file you used, the date you accessed it, and, for exact reproducibility, the git commit of [this repository](https://github.com/Punderthings/fossfoundation).  We keep URLs and identifiers stable so that citations keep working.  We plan to publish citation metadata for each dataset, so that it can be cited directly.

## Schemas And Validation

Each dataset's schema is listed in the table above, and field descriptions live in each schema.  Foundation records are also described by the v1 [OpenAPI definition](openapi).  The crosswalk, including its evidence, is checked by its own validator, `fdncrosswalk validate`, and sponsor records by `sponsors.rb --check`.  Published API files are described on [OpenAPI and API versions](openapi).  Suggestions for improvements to make the data more useful are appreciated!  Plans for further linting and validation are on [Workflows / Help Wanted](workflow).
