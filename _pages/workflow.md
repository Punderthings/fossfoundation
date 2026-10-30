---
title: Workflows / Help Wanted
excerpt: Workflows for site maintenance, linting, and visualizing.
layout: default
permalink: /workflow
parent: About / Resources
nav_order: 21
---

Since our hand-edited data (foundations, entities, sponsorships, and the platform crosswalk) changes regularly, we need to keep it consistent to make it valuable for researchers.  As new foundations are modeled, we also download or generate secondary data, such as US 990 tax data and sponsor history, for comparison across foundations.  [Data Philosophy](data) lists every dataset and which ones are generated.

## Maintenance Runbooks

GitHub Pages and Just-The-Docs handle the static site build, and every PR must pass `bundle exec jekyll build`.  The Ruby tools have their own Gemfile; run them from the repository root after `export BUNDLE_GEMFILE=assets/ruby/Gemfile` and `bundle install`.  The full list of commands and tests is in [CONTRIBUTING.md](https://github.com/Punderthings/fossfoundation/blob/main/CONTRIBUTING.md#how-to-run-and-check-locally) and [AGENTS.md](https://github.com/Punderthings/fossfoundation/blob/main/AGENTS.md#commands).  Never hand-edit a generated file: regenerate it, and commit the source and the output together.

### When Adding Or Changing A Foundation

- Run `bundle exec ruby assets/ruby/openapi_builder.rb` to regenerate the `_foundations/list.json` lookup used by the [OpenAPI](openapi) getFoundations endpoint.
- Optionally run `bundle exec ruby assets/ruby/schema_utils.rb -a normalize` to put front matter in the default field order.

### US 990 Tax Data

When adding a US foundation, or periodically, since tax forms get updated:

- Foundations with `addressCountry: US` and a `taxID` are included.
- Run `bundle exec ruby assets/ruby/foundation_reporter.rb` with `-r` (see `--help`) to download any new `_data/p990/*.json` files and regenerate `_data/p990/foundations_990_common.csv`.

### Sponsorships

When adding or updating a sponsorship:

- Run `bundle exec ruby assets/ruby/sponsor_utils.rb --check` to see which entities are stale, changed, or failing to parse.
- Run `bundle exec ruby assets/ruby/sponsor_utils.rb` to parse all sponsorship models and websites, and generate `_data/sponsorships/*.json` sponsor data.  Review any WARNING/ERROR output on stderr: orgs that fail to parse keep their previous data, and the script exits nonzero.
- Changed sponsor lists are added to `history/sponsorships/*.json` automatically; commit those with the data.
- Occasionally run `bundle exec ruby assets/ruby/sponsor_archive.rb collect` to refresh historical lists from each model's sources (`coverage` shows gaps).
- Run `bundle exec ruby assets/ruby/sponsor_reports.rb` to generate `org-funding.json`, `sponsor-counts.json`, `sponsor-history.json`, and `sponsor-income.json` (the yearly estimates shown on foundation pages).

### Platform Crosswalk

After any change to `_data/crosswalk/`, from `assets/python/fdncrosswalk` run `uv run fdncrosswalk validate`, then `uv run fdncrosswalk export` to regenerate the JSON-LD files in `api/v1/crosswalk/`.  See [Platform Crosswalk](crosswalk).

## Help Wanted

We need more tools to ensure data consistency and automate basic visualizations.

### Schemas And Linting

JSON Schemas exist for [foundations](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json), [sponsorships](https://github.com/Punderthings/fossfoundation/blob/main/_data/sponsorships-schema.json), and the [crosswalk](https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk-schema.json), and the crosswalk has its own validator.  Still to do:

- [ ] A linter for foundation, entity, and sponsorship records:
  - Reads `.md` files, and uses the schema to validate front matter.
  - Warns on formatting and Markdown issues in document bodies (which are displayed as GitHub Pages).
  - Runs on PRs and site builds.
- [ ] A schema for [entities](entities).

### OpenAPI

Foundation records are already served read-only, as described in the [OpenAPI documentation](openapi):

```ruby
require 'yaml'
require 'open-uri'
asf = YAML.load(URI.open("https://raw.githubusercontent.com/Punderthings/fossfoundation/main/_foundations/asf.md"))
puts asf['legalName']
# YAML Hash should match _data/foundations-schema.json
```

- [ ] Complete the OpenAPI definitions for our other primary data: sponsorships, entities, budgets.
- [ ] Use the OpenAPI definitions to generate schemas and linting tools, so each dataset has one source of truth.

### Automate Secondary Datasets

- [ ] Run the US 990 and sponsorship refreshes above on a schedule, rather than by hand.

### Historical Modeling

To better understand how the FOSS ecosystem has changed, we evaluate sponsorships over time.  [`sponsor_archive`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/sponsor_archive.rb) already collects past sponsor lists, including from the Internet Archive Wayback Machine, into [`history/sponsorships/`](https://github.com/Punderthings/fossfoundation/tree/main/history/sponsorships).  Sponsorship models are dated with *effectiveDate* and *pastModels*, so older lists are priced with the levels in effect at the time; for example, the ASF's Platinum sponsorship level was originally 100K USD, but was raised to 125K USD.  Help is wanted extending history further back, and adding past models for more organizations; see [Sponsorship Models](sponsorships).
