---
title: FOSS Foundation Model
excerpt: Modeling organizational, policy, and fiscal metadata of organizations.
layout: default
permalink: /fdnmodel
parent: Data Models
nav_order: 5
---

The Foundation model describes one non-profit FOSS organization per record: its legal identity, governance, policies, and funding.  It is the primary dataset of this directory; see [Data Philosophy](data) for the other datasets.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

## Foundations Model Overview

Each foundation is stored as a single `_foundations/<identifier>.md` file, for example [`_foundations/asf.md`](https://github.com/Punderthings/fossfoundation/blob/main/_foundations/asf.md).  Each file is a standard Jekyll document: [YAML front matter](https://jekyllrb.com/docs/front-matter/) holding the structured fields, then a `---` YAML document separator, then a single factual sentence describing the organization.  New records start from the [foundation template](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundation-template.md).

- **Keep Updates Simple** Each foundation is a separate text-based document, making updates simple to make and review via GitHub PRs to ensure data accuracy.
- **Enough Structured Data** Metadata follows a [simple schema](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json), with a goal to be "good enough" for common research cases.  Researchers needing more structured data are welcome to collaborate and add new fields or features.
- **Human Readable Formats** Using YAML and Markdown with GitHub Pages ensures the directory can be simple to understand for anyone, and can be a resource for anyone in open source who wants to learn about foundations.

## Inclusion Criteria

Our focus is on legal organizations that host, organize, and help sustain major open source projects around the world - commonly called foundations.  Since there are many, many variations of important organizations in the FOSS world, we are currently focusing on some specific criteria.  Submissions of additional organizations are always reviewed.

- **Organizations, People, And Funding** We record organizations, the people who lead them, and how they are funded.  Data about code, packages, repositories, and similar technical details is left to [ecosyste.ms](https://ecosyste.ms/) and similar services, which we link to through the [platform crosswalk](crosswalk).
- **Legal Organizations** Only tracking legally chartered/incorporated/etc organizations means we can look for bylaws, legal governance documents, and other tax or funding facts about these groups.
- **Non-Profits** For-profit entities have commercial goals often seen as outside the scope of many FOSS projects, and also have ample opportunity to market their own work.  We are focused on legally non-profit organizations.
- **Project Hosts** The most important orgs to include are those that host one or more open source software projects.  This ranges from the ASF with 200+ projects, to KDE which primarily hosts just the KDE distribution.
- **Other FOSS Ecosystem Orgs** Many other non-profits don't directly host software projects, but are nonetheless critically important for the open source ecosystem.  Organizations like the EFF, OSI and Wikimedia are also included, even though their impact on projects is more indirect.

Things that may be listed informally, but not as vetted data sets, include: [commercial companies](commercial) (of any kind), and the many non-incorporated open source projects without legal organizations.  Limited listings of [individual open source projects](projects) hosted at foundations are included to help provide context.

Note that foundations are incorporated under many different forms around the world:

* In the US, most are 501(c)(3) charities or 501(c)(6) trade associations.
* In the UK, non-profit status and charity status are distinct: a UK foundation might be registered as a [company limited by guarantee][clg] that does not allow profit distribution; and this organization may or may not have [charity status][charitable-purposes].
* …and other jurisdictions operate differently.

For this reason, when deciding whether an organization should be classified as a foundation, it's important to understand the requirements for non-profit status in that organization's specific jurisdiction.  Records give the type in `nonprofitStatus`, using [Schema.org NonprofitType](https://schema.org/NonprofitType) values.

[clg]: https://en.wikipedia.org/wiki/Company_limited_by_guarantee
[charitable-purposes]: https://www.gov.uk/setting-up-charity/charitable-purposes

## Model Structure

The core model starts with [Schema.org's Organization type](https://schema.org/Organization), since foundations are always legal entities.  We include a subset of Organization fields that cover common attributes that would be useful for selection or discovery.  We then add a number of new fields around governance (both board and technical), IP policies, sponsorships/funding, brand, as well as a selection of common policy URLs for FOSS foundations (when they exist).

### How Records Connect

The `identifier` is the foundation's stable id, and links its record to our other datasets:

- Sponsorship programs in `_sponsorships/`, named in the `sponsorships` field; see [Sponsorship Models](sponsorships).
- Code host and package registry accounts in `_data/crosswalk/<identifier>.json`; see [Platform Crosswalk](crosswalk).
- Hosted projects in `_data/projects-<identifier>.csv`; see [hosted projects](projects).
- US IRS 990 data, found by `taxID`; see [US 990 Taxes Model](taxes).
- `wikidataId` links the record to [Wikidata](https://www.wikidata.org/).

## Schemas And Validation

See the [OpenAPI spec for the Foundation model schema](/openapi/#responses-getFoundationById-200-schema) and fieldlist.  This is derived from the underlying [_data/foundations-schema.json](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) file.  Suggestions for improvements to make the data more useful are appreciated!  See also schemas and datastore notes for our other datasets, like [sponsorships](sponsorships), the [platform crosswalk](crosswalk), [taxes](taxes), and [budgets](budgets).

## Tooling

### Current Tooling

Most tools print their options with `--help`.  The commands for running tools and tests are in [CONTRIBUTING.md](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md#how-to-run-and-check-locally) and [AGENTS.md](https://github.com/Punderthings/fossfoundation/blob/main/AGENTS.md#commands).

- Linting: [`schema_utils -a normalize`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/schema_utils.rb) reads foundation records, then lints and reformats them to be in a default field order and schema-valid in most cases.  Any additional fields that have been added are moved to the end of the frontmatter section.
- OpenAPI building: [`openapi_builder`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/openapi_builder.rb) reads foundation records, creates the crossreference data to lookup domainnames from ids, etc., and writes out `_foundations/list.json` to serve as the getFoundations endpoint in [`openapi/v1/openapi.yaml`](https://github.com/Punderthings/fossfoundation/blob/main/openapi/v1/openapi.yaml); see [OpenAPI Documentation](openapi).
- Financial reports: [`foundation_reporter`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/foundation_reporter.rb) reports on field usage, downloads US IRS 990 data for records with a US `taxID`, and can download UK Charity Commission data; see [US 990 Taxes Model](taxes).
- Crosswalk: [`fdncrosswalk`](https://github.com/Punderthings/fossfoundation/tree/main/assets/python/fdncrosswalk) validates the platform crosswalk files and exports them as JSON-LD; see [Platform Crosswalk](crosswalk).

## Roadmap / Contributions Wanted

Our key needs are:

- Adding more data!  If you are associated with a foundation that fits our criteria, please [add your organization's data](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!
- Suggesting improvements to the data model, so that it can be useful for a broader set of [research purposes](/research) or for lookup purposes like [Issue #38](https://github.com/Punderthings/fossfoundation/issues/38).
- Verifying and dating existing records, since most fields don't yet record when they were last checked.
- Improving linting / data validation for foundation records, especially on pre-PR hooks.  The crosswalk already has a validator (`fdncrosswalk validate`).
