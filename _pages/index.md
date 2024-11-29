---
title: Welcome And Introduction
excerpt: A rich metadata directory of open source foundations, useful for research and FOSS developers alike.
layout: home
permalink: /
nav_order: 1
---

<details markdown="block">
  <summary>
    Table of contents
  </summary>
  {: .text-delta }
- TOC
{:toc}
</details>

Welcome to the FOSS Foundations Metadata directory!  We are eager to collaborate with [academic researchers](/research) and open source practitioners alike on curating rich metadata about the many excellent non-profit Foundations that either host or help open source projects succeed.

- Access the [directory of foundation metadata](listing), plus related models and data:
  - [**Sponsorship** program models](sponsorships)
  - [**Tax data** on US nonprofit foundations](taxes)
  - [Project entities that aren't legal organizations](entities) *(limited dataset)*
  - [Projects hosted at foundations](projects) *(limited dataset)*
- Read the [**roadmap** to see where we're headed](roadmap) and [OpenAPI plans](openapi).
- See the [starting philosophy around **data design**](data).
- Find useful [**resources** to learn about FOSS Foundations](resources).
- See [**research** ideas and links](research) about this dataset.
- Learn how to [**contribute** to this site](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md).
  - Be nice and respect our [Code of Conduct](CODE_OF_CONDUCT).
  - We can help you [Choose A Foundation](https://chooseafoundation.com) for your project to join.
  - Your current host, [Shane Curcuru](https://shanecurcuru.org) is looking for co-maintainers!

## Goals

- Create a rich metadata directory about nonprofit open source supporting organizations, including financial, sponsorship, governance, and other metadata.
- Store data in easy-to-update formats, and provide reliable, faceted, and discoverable access.
- Keep the site and tooling as zero/low maintenance as practical.
- Have a simple PR-driven data submission process that prevents errors.
- Attract multiple contributors to create community governance.
- Build a resource for the FOSS ecosystem that will last for 50+ years.

## Non-Goals

Volunteers are welcomed to help turn non-goals into goals, if there is interest and energy to build them!

- Tracking commercial entities.
- Tracking non-open source or free software related entities.
- Tracking non-entity projects; i.e. open source projects without legal entities.
- Fancy features, UI, or hard to maintain visualizations.  We provide a data store that others can repurpose.

## Data

Read more about our [data philosophy](data).

- Store [structured metadata](models) about Foundations in _foundations/*asf*.md frontmatter, parseable as YAML/JSON.
  - One file per foundation makes PRs simple to manage and associate with a responsible contributor.
  - Frontmatter metadata can be exposed by [OpenAPI for programmatic access](openapi).
  - Jekyll turns foundation data and Markdown bodies to human-readable websites automatically.
  - OpenAPI and GitHub Actions tooling provides linting to keep data formats clean.
- Using flat files and GitHub Pages means zero maintenance.
- Markdown body can be used for additional, unstructured data or descriptions.
- Use common human-findable identifier strings to tie in sponsorship and other models.
- Create *good-enough* data structures that can be used by practitioners and academics alike.

## Research

We are looking for research collaborations, both to validate that the metadata we're tracking is valuable to researchers, and to seek help in expanding our datasets.  Many of the [research topics](/research) related to this site will result in new paper topics, as well as impactful results for the communities you're studying.