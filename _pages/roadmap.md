---
title: Roadmap / Help Wanted
excerpt: We are building a rich metadata source about open source foundations for use by researchers.
layout: default
permalink: /roadmap
nav_order: 10
---

This site is meant to be high-level resource for anyone interested in FOSS project governance, especially those hosted at non-profit foundations or similar organizations.  Along with some introductory info - mainly pointers to existing "what is FOSS" websites out there! - it will also include a [rich metadata directory](data) of major FOSS non-profits.  This resource is meant to be [collaborative](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md), and of use to researchers, project leaders, and anyone interested in sustainability.

## Roadmap / Help Wanted

Feedback so far shows there's a lot of value in this work, both to researchers as well as to the whole ecosystem, in that we have a model that can show funding across all major FOSS Foundations - and where it comes from.  But we need your help!

- **Defining more data models**
  - Efficiently [tracking budgets](budgets) is sketched out, but needs definition, and scrapers for some common cases.
  - Tracking [non-foundation entities/projects](entities): There are many important "foundations" like the CNCF out there, but they aren't legal entities and have very different governance and finance models.  How much data do we want to track, and how large a coverage of the ecosystem is important? 
- **OpenAPI tooling, but simple**
  - Schemas need to be good enough for basic research purposes, but not so complex that PRs from new contributors cause tooling problems.
  - How can we model all data stored as [OpenAPI schemas](openapi), and then generate whatever needed shims or schemas from that single definition?  Is static raw GitHub access sufficient for read-only data purposes?
  - Recall everything must be static and served from GitHub Pages.
- **Linting, linting, linting**
  - Read about our [workflow plans and help wanted](workflow).
- **Documentation that explains**
  - The structured data we provide is non-technical, and may not be familiar to many FOSS folk - we need to explain why this work is [important for overall sustainability](research).
  - Budget financial data may be drawn from *approximate* figures (on annual reports, for example), so we need to be very clear which monetary figures are specific or not.  Data stored for [US foundations in 990 forms](taxes) is exact, although limited to what the tax code defines.


## Tasks

- [ ] Category lists of foundations
- [ ] Metadata search page
- [ ] Connections to other metadata directories & more /resources
- [ ] [Automated linting - see workflows](workflow)
- [ ] Semi-automated data format conversion (i.e. auto-create foundations.csv upon any update to a .md file)
- [ ] Setup AllContributors bot and encourage contributions
- [ ] Find volunteers to add new foundations, fillin more metadata, and evaluate data quality
- [ ] Verify data format / inclusion criteria are useful for academic research

## Site Governance

This site is maintained by [Shane Curcuru](https://shanecurcuru.org), with the intention of attracting contributors and co-maintainers who are interested in helping FOSS foundations, projects who might want to come to foundations, and academic researchers alike.  The long-term plan is to build a community of equal maintainers to ensure site longevity.  Read the [Colophon](colophon) for how this site is built.
