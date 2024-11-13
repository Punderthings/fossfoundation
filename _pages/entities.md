---
title: Non-Foundation FOSS Entities
excerpt: Tracking important projects with fiscal hosts.
layout: default
permalink: /entities
parent: Foundations Directory
nav_order: 10
---

Many important and self-organized FOSS projects are not legal entities; however some have annual budgets managed by fiscal hosts.  We aim to host metadata for these entities to enable comparisons across the FOSS ecosystem.

## Entity Modeling

"Foundations" here are defined as legal non-profit entities: either a 501C3/C6 in the US, or a registered charity in various other countries.  That enables tracking and comparisons of governance, finances, and other organizational factors that are legally required.  Non-foundation entities may also have governance and a budget, but have different kinds of constraints than legal entities.  *Work in progress.*

- identifier: similar to foundations, name of the file, for easy lookups to sponsorship models
- commonName, description, and other common metadata about a project
- various practical policy links that apply to the project (trademarks, code of conduct, etc.)
- fiscalHost: what other entity handles finances for the project
- parentOrganization: if the entity specifically ties governance to a parent foundation - much like Linux Foundation projects inherit various internal controls.  c6 organizations likely have fiscalHost = parentOrganization.  c3 organizations may not: for example, SPI and Open Source Collective acts as fiscal hosts, but don't really restrict governance of the project itself.

## Roadmap / Contributions Wanted

Modeling entities is important to track key parts of the FOSS ecosystem that aren't legal corporations.  This includes the CNCF as well as Debian.

- [ ] Building minimal required model.
- [ ] Gather and validate any entities we want to compare (see list of sponsorships to start).
- [ ] Ensure tooling can properly compare/categorize any finance reports we build across legal entities vs. project entities.
