---
title: Data Philosophy
excerpt: Metadata standards and practices for the directory.
layout: default
permalink: /data
nav_order: 20
---

This foundation directory should curate metadata rigorously organized enough for academic research, and should be easy enough to maintain and use for any open source organizers who find it valuable.  We [encourage contributions](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md)!

## Data Organization Philosophy 

Data is stored per foundation as a single `asf.md` file per organization in the `_foundations` directory.  Each file is a standard Jekyll document with a [leading YAML frontmatter](https://jekyllrb.com/docs/front-matter/) document with structured metadata, followed by a `---` YAML document separator, followed by unstructured Markdown content.

- **Keep Updates Simple** Each foundation is a separate text-based document, making updates simple to make and review via GitHub PRs.
- **Enough Structured Data** Metadata follows a [simple schema](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json), with a goal to be "good enough" for common research cases.  Researchers needing more structured data are welcome to collaborate and add new fields or features.
- **Human Readable Formats** Using YAML and Markdown with GitHub Pages ensures the directory can be simple to understand for anyone, and can be a resource for anyone in open source who wants to learn about Foundations.

## Inclusion Criteria

Our focus is on legal organizations that host, organize, and help sustain major open source projects around the world - commonly called Foundations.  Since there are many, many variations of important organizations in the FOSS world, we are currently focusing on some specific criteria.

- **Legal Organizations** Only tracking legally chartered/incorporated/etc organizations means we can look for bylaws, legal governance documents, and other tax or funding facts about these groups.
- **Non-Profits** For-profit entities have commercial goals often seen as outside the scope of many FOSS projects, and also have ample opportunity to market their own work.  We are focused on legally non-profit organizations.
- **Project Hosts** The most important orgs to include are those that host one or more open source software projects.  This ranges from the ASF with 200+ projects, to KDE which primarily hosts just the KDE distribution.
- **Other FOSS Ecosystem Orgs** Many other non-profits don't directly host software projects, but are nonetheless critically important for the open source ecosystem.  Organizations like the OSI and WikiMedia may also be included, even though their impact on projects is more indirect.

Things that aren't included: [commercial companies](commercial) (of any kind), and the many non-incorporated open source projects without legal organizations.  Limited listings of [individual open source projects](projects) hosted at Foundations are included to help provide context.

## Schemas And Validation

A simplistic [schema for foundation metadata](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) is checked in.  Suggestions for improvements to make the data more useful are appreciated!

The [roadmap](roadmap) includes building linting and data consistency checks.  Currently, these are done manually, or via using semi-automated ruby scripts in the `assets/ruby` directory.  For example:

```ruby
# If the schema changes, partially generate the Liquid to display foundations.html
assets/ruby/schema_utils.rb schema2liquid('_data/foundations-schema.json', ...)
# This generates the bulk of the page, but needs to be manually dropped in
```
