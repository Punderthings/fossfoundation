---
title: Data Philosophy
excerpt: Metadata standards and practices for the directory.
layout: default
permalink: /data
nav_order: 20
---

This foundation directory should curate metadata rigorously organized enough for academic research, and should be easy enough to maintain and use for any open source organizers who find it valuable.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

## Data Organization Philosophy

All data, basic instructions and explanations about the site, and basic visualizations or listings should be stored in human-editable formats, and should be served statically with minimal dependencies.  This ensures that maintenance issues don't break things, and that people with limited browsing clients can still participate.  Advanced features or larger data analysis tools should seek to minimize dependencies or any regular required maintenance.  Our data should also strive to be consistent and persistent.  This helps both casual users find the data, and helps researchers by keeping stable URLs and formats.

### Primary Dataset: FOSS Foundations

Organizational data is stored per foundation as a single `asf.md` file per organization in the `_foundations` directory.  Each file is a standard Jekyll document with a [leading YAML frontmatter](https://jekyllrb.com/docs/front-matter/) document with structured organizational metadata, followed by a `---` YAML document separator, followed by unstructured Markdown content.

- **Keep Updates Simple** Each foundation is a separate text-based document, making updates simple to make and review via GitHub PRs.
- **Enough Structured Data** Metadata follows a [simple schema](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json), with a goal to be "good enough" for common research cases.  Researchers needing more structured data are welcome to collaborate and add new fields or features.
- **Human Readable Formats** Using YAML and Markdown with GitHub Pages ensures the directory can be simple to understand for anyone, and can be a resource for anyone in open source who wants to learn about Foundations.

### FOSS Foundations Inclusion Criteria

Our focus is on legal organizations that host, organize, and help sustain major open source projects around the world - commonly called Foundations.  Since there are many, many variations of important organizations in the FOSS world, we are currently focusing on some specific criteria.

- **Legal Organizations** Only tracking legally chartered/incorporated/etc organizations means we can look for bylaws, legal governance documents, and other tax or funding facts about these groups.
- **Non-Profits** For-profit entities have commercial goals often seen as outside the scope of many FOSS projects, and also have ample opportunity to market their own work.  We are focused on legally non-profit organizations.
- **Project Hosts** The most important orgs to include are those that host one or more open source software projects.  This ranges from the ASF with 200+ projects, to KDE which primarily hosts just the KDE distribution.
- **Other FOSS Ecosystem Orgs** Many other non-profits don't directly host software projects, but are nonetheless critically important for the open source ecosystem.  Organizations like the OSI and WikiMedia may also be included, even though their impact on projects is more indirect.

Things that aren't included: [commercial companies](commercial) (of any kind), and the many non-incorporated open source projects without legal organizations.  Limited listings of [individual open source projects](projects) hosted at Foundations are included to help provide context.

## Other Primary Datasets

We also incorporate other quantifiable data about the FOSS ecosystem, especially finances, sponsorships, and structural relationships - i.e. foundations with subprojects; governance structures; and the like.

- **Entities** are self-organized and funded projects that are not legal corporations; they typically use a fiscal host.  Key examples are CNCF (a division of the Linux Foundation) and Debian (with a clear governance and budget structure, but uses SPI as a fiscal host).  This work is starting on [capturing data for key project entities](entities).
- **Sponsorships** are modeled based on ordinal levels of recurring sponsorship payments (or inkind services).  Data is drawn directly from FOSS organizations themselves.  See the [sponsorships schema and current dataset](sponsorships).
- **Budgets** are planned to be modeled as financial figures based on organizations' actual budgets, or estimated figures based on annual reports or similar materials from the organizations themselves.  This work is [just starting on definitions](budgets) (summer 2024).

## Secondary Datasets

We host some secondary datasets, which are computed or downloaded data from other sources.

- **US 990 Tax Data** is drawn from Propublica's digested IRS 990 filings, and quickly gives a solid financial overview of many US-based foundations.  We [host organizational 990 JSON data](taxes) as a convenience (but expect to keep URLs permanently).
- **Non-US Tax Data** Some countries in the EU post nonprofit financial tax data; most do not.  We are looking for help in modeling foundations outside the US!

## Schemas And Validation

A simplistic [schema for foundation metadata](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) is checked in.  Suggestions for improvements to make the data more useful are appreciated!  See also schemas and datastore notes for [sponsorships](sponsorships), [taxes](taxes), and [budgets](budgets).

Future plans include building a robust OpenAPI definition, and using that to [automatically generate schemas](workflow), linting tools, and the like to ensure data quality in an automated fashion