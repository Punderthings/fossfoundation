---
title: Welcome And Introduction
excerpt: A rich metadata directory of open source foundations, useful for research and FOSS developers alike.
layout: home
permalink: /
nav_order: 1
---

Welcome to the FOSS Foundations Metadata directory!  We are eager to collaborate with academic researchers and open source practitioners alike on curating rich metadata about the many excellent non-profit Foundations that either host or help open source projects succeed.

- Access the [directory of foundation metadata](listing), plus:
  - [Sponsorship program models](sponsorships)
  - [Tax data on US nonprofit foundations](taxes)
  - [Project entities that aren't legal organizations](entities)
- Read the [roadmap to see where we're headed](roadmap) and [OpenAPI plans](openapi).
- See the [starting philosophy around data design](data).
- Find useful [resources to learn about FOSS Foundations](resources).
- Learn how to [contribute to this site](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md).
- Be nice and respect our [Code of Conduct](CODE_OF_CONDUCT).
- We can help you [Choose A Foundation](https://chooseafoundation.com) for your project to join.
- Your current host, [Shane Curcuru](https://shanecurcuru.org) is looking for maintainers!

## Data

Read more about our [data philosophy](data).

- Store metadata about Foundations in _foundations/*asf*.md frontmatter, parseable as YAML/JSON.
  - File per foundation makes PRs simple to manage for anyone.
  - Frontmatter can be exposed by [OpenAPI for programmatic access](openapi).
  - Jekyll turns foundation data in to human-readable websites automatically.
  - OpenAPI and GitHub Actions tooling can ensure linting, updates keep data clean.
- Using flat files and GitHub Pages means zero maintenance.
- Markdown body can be used for additional, unstructured data or descriptions.
- Use common human-findable identifier strings to tie in sponsorship and other models.

## Goals

- Create a rich metadata directory about nonprofit open source organizations, including financial, sponsorship and other data.
- Data is easy to consume in multiple ways that are reliable.
- Website and any tooling are zero/low maintenance.
- Build simple PR-driven data submission that prevents errors.
- Attract multiple contributors that create community governance.

## Non-Goals

- Tracking commercial entities.
- Tracking non-entity projects; i.e. open source projects without legal entities.
- Fancy features, UI, or hard to maintain visualizations.
- Volunteers are welcomed to help turn non-goals into goals!
