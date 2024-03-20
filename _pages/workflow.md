---
title: Workflows / Help Wanted
excerpt: Workflows for site maintenance, linting, and visualizing.
layout: default
permalink: /workflow
nav_order: 21
---

Since all of our primary data (foundations, sponsorships, budgets) is updated regularly, we need to ensure some data consistency to make it valuable for researchers.  As new foundations are modeled, we also want to download or visualize various secondary data sources, for comparison to other foundations.

## Workflows / Help Wanted

GitHub Pages and Just-The-Docs handle the static site build.  But we need a lot more tools to ensure data consistency and automate basic visualizations.

### OpenAPI Generated Linting

Current plans are to complete the [OpenAPI schemas and endpoints](openapi), and then use that definition to generate linting tools for data quality, and to integrate into PR and site build processes.

- [ ] Complete OpenAPI schema spec for our primary data: foundations, sponsorships, entities, budgets.
- [ ] Build OpenAPI schemas to data file linter shim or tool for each dataset:
  - [ ] Transform OpenAPI schema into some sort of automated lint tool.
  - Linter reads .md files, and uses schema to validate frontmatter.
  - Linter should also warn on formatting and Markdown issues with .md document bodies (which are displayed as GitHub Pages).
  - Integrate linter into PRs/merges and site builds.
- [ ] Complete OpenAPI definitions for read-only data.
  - We can model datasets with OpenAPI GET operations to retrieve data, similar to:

## OpenAPI GET Data Example

```ruby
require 'yaml'
require 'open-uri'
asf = YAML.load(URI.open("https://raw.githubusercontent.com/Punderthings/fossfoundation/main/_foundations/asf.md"))
puts asf['legalName']
# YAML Hash should match _data/foundations-schema.json
```

- GET operations need to be mocked up to present listings of available data.
  - Run openapi_builder.rb to create foundations/list.json listing with crossref.
  - [ ] Build OpenAPI for other primary datasets.

### Automate Secondary Datasets

- [ ] Automate updating various secondary datasets.
  - [ ] When adding a new foundation, or periodically over time (because tax forms get updated periodically):
    - Scan _foundation/*.md where addressCountry = US and taxID is present
    - Run foundation_reporter.rb -r to download any new _data/p990/*.json files, and generate foundations_990_common.csv
  - [ ] When adding or updating a sponsorship:
    - Run sponsor_utils.rb to parse all sponsorship models and websites, and generate sponsor data; and to generate org-funding.json and sponsor-counts.json

### Define Historical Modeling Tools

To better understand how the FOSS ecosystem has changed, we should evaluate sponsorships over time, perhaps on an annual basis in the past.  We could use the Internet Archive Wayback machine to download sponsorship prospectus and listings from the past.  If we go far enough in the past, we'd need to have dated sponsorship models to account for older data.  For example, the ASF's Platinum sponsorship level was originally 100K USD, but was raised to 125K USD.
