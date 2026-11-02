<!-- SPDX-License-Identifier: Apache-2.0 -->
# Create url naming standards for datasets

2026-10-31 · Shane Curcuru

Status: new prompt; Claude to update and use as memory for this task.

## Prompt

Propose consistent URL pathing and OpenAPI or similar naming standard(s) for this website and our datasets.

GOALS:

- We have two audiences accessing our URLs; both are important:
  - Open source coders browsing our site: a person should be able to easily understand what a URL path means.
  - Researchers using standards-based tooling to search or auto-discover our datasets.
- Follow well-established standards like REST, OpenAPI, and other research oriented discovery tools around metadata and datasets.
- Maintain our data in existing file formats, so we can track changes with git, have maintainers able to easily review changes, and to keep maintenance simple.
- Have consistent URL naming standards for all datasets, even ones with different aspects or use cases.

IMPORTANT: do not change the existing /_foundations/ dataset because it is widely used and was created before our project scope grew.  Other newer datasets might change some URLs if it helps with consistency across the site.

DATASET ASPECTS:

Our datasets are varied by different aspects: type of data (an organization; a person; detailed tax data, a minimal crosswalk between our sources and ecosyste.ms), update frequency, how accuracy is determined (foundations: officers attest, taxes: assume IRS 990 is correct), hand or tool maintained, most common usage (human users frequently view on web, mostly API access), and more.  Note this list includes datasets that are planned to be added.  

| Dataset                 | Complexity                                                  | Status                                  | Accuracy                       | Uses by priority              |
| ----------------------- | ----------------------------------------------------------- | --------------------------------------- | ------------------------------ | ----------------------------- |
| Foundations             | complex; organization and multiple crosslinks               | existing                                | officer attested               | browsing; API                 |
| Entities                | simple; mostly crosslinks to websites                       | needs building out for more data        | scraped (in future)            | API                           |
| Sponsors                | simple; mostly data to uniquely identify                    | existing                                | derived                        | browsing; API; visualisations |
| Sponsorships            | complex; financial and linking data                         | existing                                | "derived, but checked"         | visualisations; API           |
| Sponsor lists           | simple; mostly crosslinks                                   | existing                                | scraped                        | API; browsing                 |
| Sponsor lists history   | historical                                                  | existing                                | derived from wayback machine   | visualisations; API           |
| Platform crosswalk      | complex; technical                                          | existing                                | "derived, but checked"         | API                           |
| Hosted projects         | simple; mostly crosslinks to websites                       | needs building out for more data        | derived                        | browsing; API                 |
| Propublica 990 tax data | complex; financial                                          | existing                                | downloaded from trusted source | visualisations; API           |
| IRS 990 tax data        | complex; financial                                          | existing                                | downloaded from trusted source | visualisations; API           |
| 990 tax data history    | historical                                                  | partly existing                         | downloaded from trusted source | visualisations; API           |
| Foundation Budgets      | complex; financial - future dataset                         | future work by scraping annual reports  | scraped; estimated             | visualisations; API           |
| Leadership              | complex; people; listings of foundation boards and officers | future work by scraping websites        | scraped and checked            | browsing; visualisations      |
| Leadership history      | historical                                                  | future work by scraping wayback machine | derived from wayback machine   | visualisations; API           |
| Non-US Tax data         | complex; financial                                          | future work by parsing tax sites        | downloaded from trusted source | visualisations; API           |

## Next Step

Propose one or more URL naming schemes we can use consistently, and explain the advantages or disadvantages based on our project goals.
