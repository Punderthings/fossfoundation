---
title: Foundation Budgets Model
excerpt: Modeling annual budgets or annual report finances.
layout: default
permalink: /budgets
nav_order: 26
---

Some nonprofits publish their official budget for review; many also publish an annual report that gives a high-line estimate of overall expenses and revenues.  Building a simple and "good enough" model here will allow inclusion of estimated finances for a lot more organizations (especially ones outside the US).

## Budget Modeling

Wouldn't it be great to have a database of revenue, expenses, and the like across the FOSS ecosystem?  What are the minimal figures that we need to track - and can actually compile for a broad enough array of organizations?  *Work in progress - contributions wanted!*

- organization: either a foundation (legal entity), or a project (unofficial entity that uses a fiscal host)
- year: calendar year for comparison
- end date: month/year that a budget ends (commonly used in reporting)
- source: where the figures were sourced from: organization, or elsewhere
- sourceurl: specific document figures were taken from
- updated: date the figures were copied from the source (in case someone restates an annual report, etc.)
- total revenue
  - What general revenue categories can we commonly find in existing annual reports?
- total expenses
  - As above: what are the top categories we can usefully track here?
- Budgets should be stored per-entity, but should have an easy way to store figures across multiple years

## Roadmap / Contributions Wanted

Budgets may not necessarily reflect actual finances, so we need to be sure to mark all data with both a source, as well as some kind of quality/range information.  For example, many non-US foundations do not have public tax filings, so we need to use any published budgets or annual reports as a proxy.  Many foundations produce annual reports with high-level revenue and expense numbers, but they are only estimates, not actual numbers.

- [ ] Build the budget model; reflect yearly budgets vs. actual finances vs. annual report estimates.
- [ ] Simplistic scrapers to detect likely "annual report" or "budget" pages.
- [ ] Data gathering and linting.
- [ ] Building comparisons between estimated budgets and actual 990 finances.
