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

We record non-profit FOSS organizations, the people who lead them, and how they are funded.  Data about code, packages, repositories, and similar technical details is left to [ecosyste.ms](https://ecosyste.ms/) and similar services, which we link to rather than copy.  Every fact should trace to a source, preferably the organization's own website.  How carefully each dataset is checked, and what we record about its sources, depends on what the dataset is for; see [How We Source Data](#sourcing) and the [rules for data](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md#rules-for-data).

## Data Organization Philosophy

All data, basic instructions and explanations about the site, and basic visualizations or listings should be stored in human-editable formats, and should be served statically with minimal dependencies.  This ensures that maintenance issues don't break things, and that people with limited browsing clients can still participate.  Advanced features or larger data analysis tools should seek to minimize dependencies or any regular required maintenance.  Our data should also strive to be consistent and persistent.  This helps both casual users find the data, and helps researchers by keeping stable URLs and formats.

## Datasets

Each dataset has its own page, which documents its fields, schema, and tools.  *Hand-edited* datasets are maintained by people through pull requests; *generated* ones are produced by our tools from other data and are never edited by hand.  This list is kept in [`_data/datasets.yml`](https://github.com/Punderthings/fossfoundation/blob/main/_data/datasets.yml), and is also published as a [DCAT](https://www.w3.org/TR/vocab-dcat-3/) catalog at [`/api/v2/catalog.jsonld`](/api/v2/catalog.jsonld) for data portals and other catalog tools.

| Dataset | What it holds | Where it lives | Schema | Maintained |
| --- | --- | --- | --- | --- |
{%- assign gh = "https://github.com/Punderthings/fossfoundation" %}
{%- for d in site.data.datasets.datasets %}
{%- if d.where %}{% assign where = d.where %}{% else %}
{%- capture where %}{% for f in d.distributions %}{% assign last = f.path | slice: -1 %}{% if last == "/" %}{% assign kind = "tree" %}{% assign size = f.path.size | minus: 1 %}{% assign fpath = f.path | slice: 0, size %}{% else %}{% assign kind = "blob" %}{% assign fpath = f.path %}{% endif %}[`{{ f.path }}`]({{ gh }}/{{ kind }}/main/{{ fpath }}){% unless forloop.last %}, {% endunless %}{% endfor %}{% endcapture %}
{%- endif %}
{%- if d.schemas %}{% capture schema %}{% for s in d.schemas %}[`{{ s }}`]({{ gh }}/blob/main/_data/{{ s }}){% unless forloop.last %}, {% endunless %}{% endfor %}{% endcapture %}{% else %}{% assign schema = d.schemaNote %}{% endif %}
| [{{ d.title }}]({{ d.page }}) | {{ d.description }} | {{ where }} | {{ schema }} | {{ d.maintained }} |
{%- endfor %}

**Entities** are self-organized and funded projects that are not legal corporations.  Key examples are CNCF (a division of the Linux Foundation) and Debian (with a documented governance and budget structure, but uses SPI as a fiscal host).

**US 990 tax data** comes from the IRS Form 990 that US nonprofits file each year, recorded from two different sources, so it is kept as two datasets.  **ProPublica 990** data quickly gives a solid financial overview of many US-based foundations; we host ProPublica's organizational 990 JSON as a convenience, and expect to keep its URLs permanently.  **IRS 990** data is parsed directly from the IRS's e-file XML, with much more detail and newer years, but in a different format with some subtly different values.  The [US 990 Taxes Model](taxes) explains both and how they differ; most researchers need only one of them.

**Crosswalk evidence** records why we believe each crosswalk link.  Most evidence is a public page anyone can check again; `human-attested` evidence is a confirmation that a trusted [attestor](crosswalk#attestors) got out of band from someone at the organization.  These attestations are given by volunteers and have not been legally reviewed to qualify as attestations under the EU Cyber Resilience Act or other legislation; see their [legal status](crosswalk#legal-status).  Records of those people are kept private by default, and are public only when the person agreed.

**Non-US Tax Data** Some countries post nonprofit financial data; most do not.  Our [`foundation_reporter`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/foundation_reporter.rb) tool can download UK Charity Commission data, stored as [`_data/taxes/uk-<charity number>.json`](https://github.com/Punderthings/fossfoundation/tree/main/_data/taxes), and we are **looking for help** in modeling foundations outside the US!  This UK data is not yet listed as a dataset: once we have more examples and a parser for it, we will add it as a proper dataset.

## How We Source Data {#sourcing}

No dataset here is filled in by guessing, but our datasets are not all used the same way, so they are not all checked the same way.  A slightly wrong board size on a foundation page misleads a reader a little.  A wrong claim that a foundation controls a package namespace could mislead someone deciding which releases to trust.  So each dataset gets the level of checking its use calls for, and stores only the sourcing that level needs.  [CONTRIBUTING.md](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md#rules-for-data) gives contributors the same rules, and AI agents follow them in [AGENTS.md](https://github.com/Punderthings/fossfoundation/blob/main/AGENTS.md#data-rules).

| Dataset | Accuracy it needs, and why | How changes are checked | What sourcing we store, and where |
| --- | --- | --- | --- |
{%- for s in site.data.datasets.sourcing %}
| {{ s.datasets }} | {{ s.accuracy }} | {{ s.checks }} | {{ s.stored }} |
{%- endfor %}

Data not yet published, such as [budgets](budgets) and [IRS 990 data](taxes#irs-990), will follow the row closest to it: budgets from organizations' own reports are approximate, and IRS 990 data is copied exactly.

## Licensing

Our licensing philosophy is to allow maximal reuse by anyone, both for datasets hosted, website presentation, and any automated tools.

Code and prose are licensed under [Apache-2.0](https://www.apache.org/licenses/LICENSE-2.0).  New datasets and data exports, such as the [sponsors](sponsors) records, the public [attestation records](crosswalk#people), and the [crosswalk exports](crosswalk#exports), are [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/).  Existing data files are currently Apache-2.0.  Each file's license is declared following the [REUSE](https://reuse.software) specification in [`REUSE.toml`](https://github.com/Punderthings/fossfoundation/blob/main/REUSE.toml).

## Citing This Data

Please cite the page or file you used, the date you accessed it, and, for exact reproducibility, the git commit of [this repository](https://github.com/Punderthings/fossfoundation).  We keep URLs and identifiers stable so that citations keep working.  We plan to publish citation metadata for each dataset, so that it can be cited directly.

## Schemas And Validation

Each dataset's schema is listed in the table above, and field descriptions live in each schema.  Foundation records are also described by the v1 [OpenAPI definition](openapi).  The crosswalk, including its evidence, is checked by its own validator, `fdncrosswalk validate`, and sponsor records by `sponsors.rb --check`.  Published API files are described on [OpenAPI and API versions](openapi).  Suggestions for improvements to make the data more useful are appreciated!  Plans for further linting and validation are on [Workflows / Help Wanted](workflow).
