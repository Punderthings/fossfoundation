---
title: Data Philosophy
excerpt: Metadata standards and practices for this project.
layout: default
permalink: /data
parent: Data Models
nav_order: 1
---

This foundation directory curates metadata that is rigorously organized enough for academic research, and is easy enough to maintain and use for any open source organizers who find it valuable.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

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
| [Sponsorships](sponsorships) | Ordinal levels of recurring sponsorship programs, drawn from each organization's own prospectus | [`_sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/_sponsorships) | [`sponsorships-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsorships-schema.json) | hand-edited |
| [Sponsor lists and history](sponsorships) | Current sponsor lists, monthly history with provenance, and summary reports | [`_data/sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/sponsorships), [`history/sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/history/sponsorships) | described on [Sponsorship Models](sponsorships) | generated |
| [Platform crosswalk](crosswalk) | Which code host and package registry accounts belong to a foundation, with evidence | [`_data/crosswalk/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/crosswalk) | [`crosswalk-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk-schema.json) | hand-edited; its [JSON-LD exports](crosswalk#exports) in `api/v1/crosswalk/` are generated |
| [Hosted projects](projects) | Projects hosted by some foundations, for context | `_data/projects-<identifier>.csv` | CSV, with column names in the header row | scraped, then reviewed by hand |
| [US 990 tax data](taxes) | ProPublica's digested IRS 990 filings for US foundations | [`_data/p990/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/p990) | ProPublica's format | generated (downloaded) |
| [Budgets](budgets) | Planned: actual or estimated budget figures from organizations' own reports | not yet | not yet | planned |

**Entities** are self-organized and funded projects that are not legal corporations.  Key examples are CNCF (a division of the Linux Foundation) and Debian (with a documented governance and budget structure, but uses SPI as a fiscal host).

**US 990 Tax Data** quickly gives a solid financial overview of many US-based foundations.  We host organizational 990 JSON data as a convenience, and expect to keep its URLs permanently.

**Non-US Tax Data** Some countries post nonprofit financial data; most do not.  Our [`foundation_reporter`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/foundation_reporter.rb) tool can download UK Charity Commission data, and we are **looking for help** in modeling foundations outside the US!

## Licensing

Code and prose are licensed under [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0).  New datasets and data exports, such as the [crosswalk exports](crosswalk#exports), are [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/).  Existing data files are currently Apache-2.0.  Each file's license is declared following the [REUSE](https://reuse.software) specification in [`REUSE.toml`](https://github.com/Punderthings/fossfoundation/blob/main/REUSE.toml).

## Citing This Data

Please cite the page or file you used, the date you accessed it, and, for exact reproducibility, the git commit of [this repository](https://github.com/Punderthings/fossfoundation).  We keep URLs and identifiers stable so that citations keep working.  We plan to publish citation metadata for each dataset, so that it can be cited directly.

## Schemas And Validation

Each dataset's schema is listed in the table above, and field descriptions live in each schema.  Foundation records are also described by the [OpenAPI definition](openapi).  The crosswalk is checked by its own validator, `fdncrosswalk validate`.  Suggestions for improvements to make the data more useful are appreciated!  Plans for further linting and validation are on [Workflows / Help Wanted](workflow).
