---
title: Roadmap and Plans
excerpt: We are building a rich metadata source about open source foundations for use by researchers.
layout: default
permalink: /roadmap
nav_order: 10
---

This site is meant to be high-level resource for anyone interested in FOSS project governance, especially those hosted at non-profit foundations or similar organizations.  Along with some introductory info - mainly pointers to existing "what is FOSS" websites out there! - it will also include a rich metadata directory of major FOSS non-profits.  This resource is meant to be collaborative, and of use to researchers, project leaders, and anyone interested in sustainability.

## Version 0.1 plans

- Overview homepage - what is this project.
- Resources page - point to the key resources already out there about governance, sustainability, and other non-technical open source concepts.
- `/listing/` directory - a friendly listing of all FOSS Foundations in our dataset, with simple categorization/sorting/search features.
- `/data/` directory - metadata about foundations, as YAML/JSON files, one per foundation, like: fsf.yaml
- Basic build/lint tooling
- Provide auto-build of alternate formats (like .csv out of .yaml)

## Example

```ruby
require 'yaml'
require 'open-uri'
# Future plans: have more stable programmatic URL and listing features; offer CSV and other formats
asf = YAML.load(URI.open("https://raw.githubusercontent.com/Punderthings/fossfoundation/main/_foundations/asf.md"))
puts asf['legalName']
```

## Tasks

- [x] Organize homepage & sketch nav structure -sc
- [x] Resources page - sc (started)
- [x] Colophon - sc
- [ ] CONTRIBUTING
- [ ] Tweak theme / logo?
- [x] Metadata schema (format?) -sc ('good-enough' level)
- [x] csv2yaml converter & checkin data -sc
- [x] /listing/ directory page: name/url, nonprofitStatus / taxID, accepts new projects, description? boardType? other?
- [ ] Individual foundation data page, with all fields, read from schema
- [ ] Category lists of foundations
- [ ] Metadata search page
- [ ] Connections to other metadata directories
- [ ] Automated linting
- [ ] Semi-automated data format conversion (i.e. auto-create foundations.csv upon any update to a .md file)

## Site Governance

This site is maintained by [Shane Curcuru](https://shanecurcuru.org), with the intention of attracting contributors and other co-maintainers who are interested in helping FOSS foundations, projects who might want to come to foundations, and academic researchers alike.  The long-term plan is to build a community of equal maintainers to ensure site longevity.  Read the [Colophon](colophon) for how this site is built.
