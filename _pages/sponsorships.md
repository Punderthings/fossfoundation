---
title: Sponsorship Models
excerpt: Modeling sponsorship programs across the FOSS landscape.
layout: sponsorships
permalink: /sponsorships
parent: Data Models
nav_order: 30
---

To provide context for financial sustainability around FOSS organizations, we've built a model to roughly compare common sponsorship programs across foundations or popular projects.

## Modeling Foundation Sponsorship Programs

Data is stored per entity (a foundation or a project) as a single `asf.md` file in `_sponsorships`, see a [listing below](#listing).  Each file is a set of factual references to the entity's published sponsorship policies and levels, and provides metadata to scrape web pages of actual sponsor listings at the current date.  Some entries will provide a dated static map of manually compiled list of current sponsors listed.

## Inclusion Criteria

Since many projects with well-known sponsorship programs use separate entities as fiscal hosts, sponsorships are modeled by common project name, and mapped to their fiscal host if it's under a different name.

- **Funding Sponsorships** The primary focus is on traditional sponsorships, where an outside entity provides funding (contribution, grant, etc.) to the FOSS entity.  We track cash funding levels separately from documented in-kind levels (i.e. service providers donating the service, not the cash).
- **FOSS Entities** We are only modeling common FOSS sponsorship programs where we can easily detect what funding levels are available, and can either easily scrape, or manually create a static map of actual current sponsors.
- **Sponsor Levels** To make rough statistical comparisons, all sponsorship levels documented by an entity are mapped to an ordered set of metalevels.  This allows analysis of the highest level or top-line sponsor - typically seen as more prestigious - from other levels and the like.
  - Ordinal levels `first, second`, etc. are traditional sponsorship tiers in descending amount.
  - In-kind levels `firstinkind, secondinkind` etc. are in-kind or services sponsorships.  These are counted at full level for the entity, but are discounted in reporting when counting the value sponsors are giving overall (since services typically don't cost the sponsor as much as cold hard cash).
  - `community` is a common type of level for community groups, supporters, associated entities, or the like.  It usually has a very low or zero amount cost.
  - A few other types of levels are commonly seen, so we have mapped them to *similar enough* categories `academic, grants, enduser`. 
- **Not Event Sponsorships** We focus on sponsorship relationships with entities that generally expect a recurring payment.  Event-specific sponsorships, even for recurring events, are not currently tracked (although we'd be happy to have contributions to do so!)
- **Traditional Sponsorships** The focus here are on traditional "give our nonprofit a check, and we'll showcase your logo" sponsorships.  Different models need to be built to showcase various pass-through and bundling-funds entities like Tidelift, Open Source Collective, and the like.
- **Only Public Data** We track the actual sponsorships listed by entities themselves, not press releases or statements by sponsors.
- **Financial Figures Are Approximate** While sponsorship level amounts are taken directly from entity programs, the actual funds a specific sponsor may pay any year could vary.  All financial numbers, especially top-line reports, are estimates only.

### Sponsorship Model Structure

Sponsorships are dated, to enable future review of sponsorships over time via using the [Wayback Machine](https://archive.org/) or similar tools to capture past listed sponsors.  Other fields used include: (see also [prototype sponsorships-schema.json](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsorships-schema.json))

- *nonprofit:* what type of US nonprofit: c3, c6, or `lf` for Linux Foundation projects.
- *sponsorurl:* URL listing current entity sponsors to scrape programmatically.
- *levelurl:* URL listing the entity's sponsorship levels and benefits to parse as HTML.
- *staticmap:* If present, use the manually compiled static listing of sponsors below, as of that date.
- *landscape:* If present, treat *sponsorurl* as a [CNCF style landscape.yml](https://github.com/cncf/landscape2) for current sponsor listing.
- *sponsormap:* If present, load a mapping of detected URL hrefs to sponsor hostnames; this simplifies some more complex scraping tooling.
- *normalize:* If tooling should normalize URLs to bare hostnames (to more simply map to common commercial companies).
- *levels:* Is a hash listing of all meta levels the current entity advertises.
  - *first:* First is the meta level we map this to.
  - *name:* Name of the level the entity uses.
  - *amount:* USD cash amount the entity notes for a typical sponsorship.
  - *amountvaries:* If present, describe how the sponsorship cash amount varies; we list the highest part of the range in *amount* above.
  - *selector:* CSS selector to find a nodelist of elements that are sponsor listings.
  - *attr:* Attribute to copy from the selector's nodelist.
  - **benefits:** A rough guide to the kinds of benefits the entity provides at this sponsorship level.  Higher levels assume all benefits from lower levels unless noted otherwise.
    - *governance:* If the sponsor gets direct rights in entity governance: typically sponsors can either appoint a board seat, or are eligible to vote in board elections.
    - *advisory:* If the sponsor gets access to an advisory council, the entity leadership or other committees, or the like.
    - *events:* Event tickets, discounts, or additional sponsorship opportunities.
    - *services:* Training or other services provided or discounted.
    - *marketing:* Any outreach, marketing, or similar that the entity will provide for or work with the sponsor in conjunction on, like shared press releases.
    - *logo:* Any specific notes on how a sponsor's logo is displayed (or not displayed). 

## Tooling

### Current Tooling

- [`sponsor_utils`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/sponsor_utils.rb) reads sponsorship models, and then parses either html or yml (or a staticmap) to scrape a sponsor listing and produce a hash mapping for that entity.
- [`sponsor_reports`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/sponsor_reports.rb) reads the output above, and creates simple reports.  Reports focus on mapping sponsors to entities and vice-versa, as well as totaling approximate sponsorship values shown for all tracked entities.


## Roadmap / Contributions Wanted

There are many improvements we'd love to see contributed, especially in terms of helping to clearly explain the limitations of this model.  In particular, the actual cash amounts are only approximations valid for general statistical purposes.

- [ ] Add tracking for different currencies.
- [ ] Validate general model is valuable and provides good-enough comparisons across the FOSS ecosystem.
- [ ] Validate various entity models.
- [ ] Build historical scraping tools for entities we can use Wayback Machine on their websites.
- [ ] Improve reports and add visualizations.
- [ ] Build comparisons with other financial data or [US IRS 990 figures](taxes); i.e. rough sponsorship income from a model vs. the 990's contributions amount.
