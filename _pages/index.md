---
title: Welcome And Introduction
excerpt: A rich metadata directory of open source foundations, funding, and leadership - by practitioners; for researchers.
layout: home
permalink: /
nav_order: 1
---

> How do people organize open source collaboration *at scale*?

This FOSS Foundations directory is collection of datasets about the many
excellent non-profit Foundations that directly host or otherwise help open
source projects succeed.

We welcome [academic researchers](/research) studying the
organizations behind open source, and serve as a showcase for the organizations
and communities behind much of the software ecosystem today.

- Access the [directory of FOSS foundations](listing), and related datasets:
  - [**Sponsorship** program models](sponsorships)
  - [**Financial tax data** on US nonprofit foundations](taxes)
  - [Other entities hosted by foundations](entities) *(limited dataset)*
  - [Crosswalk of foundation-owned registries or distributions](crosswalk)
- Read the [**roadmap** to see where we're headed](roadmap) and [OpenAPI plans](openapi).
- See our [philosophy of **data design**](data).
- Find useful [**resources** to learn about FOSS Foundations](resources).
- See [**research** ideas and links](research) about this dataset.
- Learn how to [**contribute** to this site](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md).
  - Be nice and respect our [Code of Conduct](CODE_OF_CONDUCT).
  - We can help you [Choose A Foundation](https://chooseafoundation.com) for your project to join.
  - Your current host, [Shane Curcuru](https://shanecurcuru.org) is looking for co-maintainers!

## Goals

- Create a rich metadata directory about nonprofit open source supporting organizations, including financial, sponsorship, governance, leadership, and other metadata.
- Store data in easy-to-update formats, and provide reliable, faceted, and discoverable access.
- Curate accurate and historical data with discoverable attestations.
- Keep the site and tooling as zero/low maintenance as practical.
- Have a simple PR-driven data submission process that prevents errors.
- Attract multiple contributors to create community governance.
- Build a resource for the FOSS ecosystem that will last for 50+ years.

## Non-Goals

Volunteers are welcomed to help turn non-goals into goals, if there is interest and energy to build them!

- Tracking commercial entities.
- Tracking non-open source or free software related entities.
- Tracking non-entity projects; i.e. open source projects without legal entities.
- Building datasets easily accessible elsewhere, like [Ecosyste.ms](https://ecosyste.ms/).
- Fancy features, UI, or hard to maintain visualizations.  We provide a data store that others can repurpose.

## Data

Read more about our [data philosophy](data).

- Store [structured metadata](models) about Foundations in _foundations/*asf*.md frontmatter, parseable as YAML/JSON.
  - One file per foundation makes PRs simple to manage and associate with a responsible contributor.
  - Frontmatter metadata can be exposed by [OpenAPI for programmatic access](openapi).
  - Jekyll turns foundation data and Markdown bodies to human-readable websites automatically.
  - OpenAPI and GitHub Actions tooling provides linting to keep data formats clean.
- Using flat files and GitHub Pages means zero maintenance and detailed change history.
- Markdown body can be used for additional, unstructured data or descriptions.
- Use common human-findable identifier strings to tie all models together.
- Create *good-enough* data structures for practitioners and academics alike.

## Research

We are looking for research collaborations, both to validate that the metadata we're tracking is valuable to researchers, and to seek help in expanding our datasets.  Many of the [research topics](/research) related to this site will result in new paper topics, as well as impactful results for the communities you're studying.
