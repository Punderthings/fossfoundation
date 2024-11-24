---
title: Data Philosophy
excerpt: Metadata standards and practices for this project.
layout: default
permalink: /data
parent: Data Models
nav_order: 1
---

This foundation directory curates metadata that is rigorously organized enough for academic research, and is easy enough to maintain and use for any open source organizers who find it valuable.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

## Data Organization Philosophy

All data, basic instructions and explanations about the site, and basic visualizations or listings should be stored in human-editable formats, and should be served statically with minimal dependencies.  This ensures that maintenance issues don't break things, and that people with limited browsing clients can still participate.  Advanced features or larger data analysis tools should seek to minimize dependencies or any regular required maintenance.  Our data should also strive to be consistent and persistent.  This helps both casual users find the data, and helps researchers by keeping stable URLs and formats.

## Primary Dataset: FOSS Foundations

See the [overview of the Foundation model](fdnmodel) or go straight to the [OpenAPI spec](/openapi).

## Other Primary Datasets

We also incorporate other quantifiable data about the FOSS ecosystem, especially finances, sponsorships, and structural relationships - i.e. foundations with subprojects; governance structures; and the like.

- **Entities** are self-organized and funded projects that are not legal corporations; they typically use a fiscal host.  Key examples are CNCF (a division of the Linux Foundation) and Debian (with a documented governance and budget structure, but uses SPI as a fiscal host).  This work is starting on [capturing data for key project entities](entities).
- **Sponsorships** are modeled based on ordinal levels of recurring sponsorship payments (or inkind services).  Data is drawn directly from FOSS organization sponsorship prospectus themselves.  See the [sponsorships schema and current dataset](sponsorships).
- **Budgets** are planned to be modeled as financial figures based on organizations' actual budgets (when published), or estimated figures based on annual reports or similar materials from the organizations themselves.  This work is [just starting on budget definitions](budgets).

## Secondary Datasets

We host some secondary datasets, which are computed or downloaded data from other sources.

- **US 990 Tax Data** is drawn from Propublica's digested IRS 990 filings, and quickly gives a solid financial overview of many US-based foundations.  We [host organizational 990 JSON data](taxes) as a convenience (but expect to keep URLs permanently).
- **Non-US Tax Data** Some countries in the EU post nonprofit financial tax data; most do not.  We are **looking for help** in modeling foundations outside the US!

## Schemas And Validation

A simplistic [schema for foundation metadata](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) is checked in.  Suggestions for improvements to make the data more useful are appreciated!  See also schemas and datastore notes for [sponsorships](sponsorships), [taxes](taxes), and [budgets](budgets).

Future plans include building a robust OpenAPI definition, and using that to [automatically generate schemas](workflow), linting tools, and the like to ensure data quality in an automated fashion.