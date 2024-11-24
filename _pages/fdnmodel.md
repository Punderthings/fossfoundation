---
title: FOSS Foundation Model
excerpt: Modeling organizational, policy, and fiscal metadata of organizations.
layout: default
permalink: /fdnmodel
parent: Data Models
nav_order: 5
---

This foundation directory curates metadata that is rigorously organized enough for academic research, and is easy enough to maintain and use for any open source organizers who find it valuable.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

## Foundations Model Overview

Organizational data is stored per foundation entity as a single `asf.md` file in the `_foundations` directory.  Each file is a standard Jekyll document with a [leading YAML frontmatter](https://jekyllrb.com/docs/front-matter/) document with structured organizational metadata, followed by a `---` YAML document separator, followed by semi-structured Markdown content.

- **Keep Updates Simple** Each foundation is a separate text-based document, making updates simple to make and review via GitHub PRs to ensure data accuracy.
- **Enough Structured Data** Metadata follows a [simple schema](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json), with a goal to be "good enough" for common research cases.  Researchers needing more structured data are welcome to collaborate and add new fields or features.  [OpenAPI support is planned](openapi)!
- **Human Readable Formats** Using YAML and Markdown with GitHub Pages ensures the directory can be simple to understand for anyone, and can be a resource for anyone in open source who wants to learn about Foundations.

## Inclusion Criteria

Our focus is on legal organizations that host, organize, and help sustain major open source projects around the world - commonly called Foundations.  Since there are many, many variations of important organizations in the FOSS world, we are currently focusing on some specific criteria.  Submissions of additional organizations are always reviewed.

- **Legal Organizations** Only tracking legally chartered/incorporated/etc organizations means we can look for bylaws, legal governance documents, and other tax or funding facts about these groups.
- **Non-Profits** For-profit entities have commercial goals often seen as outside the scope of many FOSS projects, and also have ample opportunity to market their own work.  We are focused on legally non-profit organizations.
- **Project Hosts** The most important orgs to include are those that host one or more open source software projects.  This ranges from the ASF with 200+ projects, to KDE which primarily hosts just the KDE distribution.
- **Other FOSS Ecosystem Orgs** Many other non-profits don't directly host software projects, but are nonetheless critically important for the open source ecosystem.  Organizations like the EFF, OSI and WikiMedia are also be included, even though their impact on projects is more indirect.

Things that may be listed informally, but not as vetted data sets, include: [commercial companies](commercial) (of any kind), and the many non-incorporated open source projects without legal organizations.  Limited listings of [individual open source projects](projects) hosted at Foundations are included to help provide context.

## Model Structure

The core model starts with [Schema.org's Organization type](https://schema.org/Organization), since Foundations are always legal entities.  We include a subset of Organization fields that cover common attributes that would be useful for selection or discovery.  We then add a number of new fields around governance (both board and technical), IP policies, sponsorships/funding, brand, as well as a selection of common policy URLs for FOSS Foundations (when they exist).

## Schemas And Validation

See the [OpenAPI spec for the Foundation model schema](/openapi/#responses-getFoundationById-200-schema) and fieldlist.  This is derived from the underlying [_data/foundations-schema.json](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) file.  Suggestions for improvements to make the data more useful are appreciated!  See also schemas and datastore notes for our other datasets, like [sponsorships](sponsorships), [taxes](taxes), and [budgets](budgets).

## Tooling

### Current Tooling

- [`schema_utils -a normalize`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/schema_utils.rb) reads foundation records, then lints and reformats them to be in a default field order and schema-valid in most cases.  Any additional fields that have been added are moved to the end of the frontmatter section.

## Roadmap / Contributions Wanted

Our key needs are:

- Adding more data!  If you are associated with a Foundation that fits our criteria, please [add your organization's data](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!
- Suggesting improvements to the data model, so that it can be useful for a broader set of [research purposes](/research).
- Improving linting / data validation especially on pre-PR hooks.
