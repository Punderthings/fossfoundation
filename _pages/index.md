---
title: Welcome And Introduction
excerpt: A rich metadata directory of open source foundations, useful for research and FOSS developers alike.
layout: home
permalink: /
nav_order: 1
---

Welcome to the FOSS Foundations Metadata directory!  We are eager to collaborate with academic researchers and open source practitioners alike on curating rich common metadata about the many excellent non-profit Foundations that either host or help open source projects succeed.

- Discover the [directory of foundation metadata](listing), plus:
  - [Sponsorship program models](sponsorships)
  - [Tax data on US nonprofit foundations](taxes)
  - [Project entities that aren't legal organizations](entities)
- Read the [roadmap to see where we're headed](roadmap) and [OpenAPI plans](openapi).
- See the [starting philosophy around data design](data).
- Find useful [resources to learn about FOSS Foundations](resources).
- Learn how to [contribute to this site](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md).
- Be nice and respect our [Code of Conduct](CODE_OF_CONDUCT).
- We can help you [Choose A Foundation](https://chooseafoundation.com) for your project to join.
- Learn about your current host, [Shane Curcuru](https://shanecurcuru.org).

## Goals

- Create a rich metadata directory about nonprofit open source organizations.
- Data is easy to consume in multiple ways that are reliable.
- Website and any tooling are zero/low maintenance.
- Build simple PR-driven data submission that prevents errors.
- Attract multiple contributors that create community governance.

## Non-Goals

- Tracking commercial entities.
- Tracking non-entity projects; i.e. open source projects without legal entities.
- Fancy features, UI, or hard to maintain visualizations.
- Volunteers are welcomed to help turn non-goals into goals!

## Data

Read more about our [data philosophy](data).

- Store basic metadata in _foundations/*asf*.md frontmatter, parseable as YAML
  - Individual files makes PRs very simple and limited to the organization you're updating
  - Most data fields are purely optional, since we rely on volunteers to research data
- Store unstructured data as the body of the .md documents, meaning they can be self-describing
- Workflow expects to maintain _foundations files, and then use Actions to auto-build alternate data formats
- Using flat files / GitHub Pages means zero maintenance
- Will store a subset of metadata for commercial organizations and independent projects
  - People searching for a project will see if it's a non-profit (in main data source) or not
