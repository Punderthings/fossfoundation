---
title: US 990 Taxes Model
excerpt: Modeling US IRS 990 form finances for nonprofits, from ProPublica and from the IRS itself.
layout: default
permalink: /taxes
parent: Data Models
nav_order: 10
---

US based nonprofits must file an IRS Form 990 every year, even though they may not pay taxes.  These forms are official, public, and broadly consistent across organizations, which makes them the most reliable way we have to compare the finances of US foundations over time.  International foundation tax law varies by country, so more research is needed there!

## Model Overview: 990 Filings By Foundation

Our tax model is **historical data from official government 990 forms, recorded per foundation**:

- Each US foundation is identified by its EIN, the `taxID` field of its [foundation record](fdnmodel).  Tools read the EINs from `_foundations/*.md`.
- Each foundation's data holds the list of its filings, one per fiscal year, so the filings list is the history.  A filing is a Form 990, the shorter 990-EZ for smaller organizations, or a 990-PF for private foundations.
- Each filing has a common set of **core totals**: total revenue (`totrevenue`), total functional expenses (`totfuncexpns`), contributions, gifts and grants (`totcntrbgfts`), program service revenue (`totprgmrevnue`), investment income (`invstmntinc`), and end-of-year assets, liabilities and net assets (`totassetsend`, `totliabend`, `totnetassetend`).  These names come from ProPublica's Form 990 data, and both sources below use them for Form 990 filings.

990 filings provide a consistent way to see total revenue, expenses, and assets for any US nonprofit.  They also provide some level of detail within those numbers, in terms of amount of contributions (voluntary donations) versus program expenses or other types of income.  Each foundation page shows its revenue and expenses by year in its **Tax Filings** section.

We record this data from **two different sources**, which have different tools and formats, so they are kept as separate datasets: [ProPublica 990](#propublica-990) and [IRS 990](#irs-990).  They describe the same filings but differ in subtle ways (see [how they differ](#differences)), and most researchers need only one of them.  This split was decided in the [URL naming plan](https://github.com/Punderthings/fossfoundation/blob/main/_prompts/2026-11-01-url-standards-for-datasets.md) (decision 5), which also reserves the future API paths `/api/v2/propublica-990/<id>.json` and `/api/v2/irs-990/<id>.json`.

### US 990 Data Notes

- **Time Lag** Nonprofits often file taxes late; it also takes a long time for the IRS to publish them, and then ProPublica or other aggregators to parse and quantify them.
- **Data Errors** I have seen a few figures in ProPublica's rolled-up organization object that were wrong, likely due to scanning or importing errors in their process.
- **Categorization** We need to create a guide showing exactly what 990 field values mean in FOSS Foundation contexts.  "Contributions, gifts, grants, and similar amounts received" is a fairly clear number that can be (almost) compared between 990 and 990-EZ forms.  But it's not always clear to a reader what "Program Service Revenue" means for the typical foundation.
- **Fiscal Years** Many foundations don't use the calendar year, so "the 2024 filing" can mean different periods.  Match filings on the month the fiscal year ends, not on a year label.
- **US Only** Making direct comparisons from 990 forms to other country tax (or similar) forms will be challenging.

## ProPublica 990 {#propublica-990}

[ProPublica's Nonprofit Explorer](https://projects.propublica.org/nonprofits/) makes it simple to report on annual tax-reported income, expenses, and more for US based foundations.  ProPublica builds its data from official IRS data releases of processed tax filings.

- **Data:** one `<ein>.json` file per organization in [`_data/p990/`](https://github.com/Punderthings/fossfoundation/tree/main/_data/p990), exactly as ProPublica's API returns it.  We store this data for convenience, and in case ProPublica's datastore ends.
- **Format:** IRS-defined metadata about the nonprofit in the `organization` object, then `filings_with_data`, the filings ProPublica has parsed, with about 70 summary fields each, and `filings_without_data`, newer or unparsed filings that have only a PDF link.  Full details are in [ProPublica's API reference](https://projects.propublica.org/nonprofits/api).
- **Tools:** [`foundation_reporter`](https://github.com/Punderthings/fossfoundation/blob/main/assets/ruby/foundation_reporter.rb) `-r` reads foundation records for EINs, then uses the Ruby [`propublica990`](https://github.com/Punderthings/propublica990) library to download and cache ProPublica's JSON and write a summary CSV, `_data/p990/foundations_990_common.csv`.  Note that Jekyll doesn't always like subdirectories that start with digits.
- **Best for:** a quick, long-running financial overview of many foundations, in a widely used format.

## IRS 990 {#irs-990}

The IRS publishes the e-filed 990 returns themselves as XML, every month.  Reading them directly gives recent years as soon as the IRS releases them, and far more detail than ProPublica's summary.

- **Tool:** [`foss990parser`](https://github.com/Punderthings/foss990parser), a separate Python tool.  It collects our EINs, finds each foundation's filings in the IRS yearly e-file indexes, downloads each return's XML from the [GivingTuesday 990 Data Lake](https://990data.givingtuesday.org/) or the IRS's own zip files, and parses it.  Field names were checked against the Nonprofit Open Data Collective's [Master Concordance File](https://github.com/Nonprofit-Open-Data-Collective/irs-efile-master-concordance-file).
- **Format:** one JSON file per organization, with every filing newest first.  Each filing has the same core totals as ProPublica, plus provenance (IRS object id, processing year, source), Part I and VI headcounts and board size, Part IX functional expenses split into program, management and fundraising, the Part X balance sheet, officer pay, the highest-paid contractors, Schedule I grants, and Schedule R related organizations.  Cross-organization CSV tables come with a [Frictionless Data](https://frictionlessdata.io/) `datapackage.json` describing every column.  990-PF returns are listed with header data only.
- **Privacy:** when publishing, the tool withholds the names of individual people (officers and contractors paid as persons) and reduces addresses to city, state and country.
- **Status:** the tool works, but its data is not yet published in this repository.  When it is, it will follow the `irs-990` dataset layout in the URL plan.
- **Best for:** recent years, and research into how foundations fund themselves and spend their money.

## How ProPublica and IRS Data Differ {#differences}

Most core totals agree, but a few subtle differences matter when comparing or combining them:

| Point | ProPublica 990 | IRS 990 |
| --- | --- | --- |
| **Year labels** | `tax_prd_yr` is the year the fiscal year *ends*. The ASF's fiscal year May 2024 to April 2025 is **2025** (`tax_prd` 202504). | IRS `TaxYr` is the year the fiscal year *begins*, so the same ASF filing is **2024**. Both share the period end month (`tax_period` 202504), which is the safe key. |
| **Recent years** | Parsed a year or more after filing. In our copy, that ASF filing appears only under `filings_without_data`, with a PDF link and no figures. | Available once the IRS releases the XML. The same filing reports total revenue of $2,220,257 and total expenses of $2,334,727. |
| **Not reported vs. zero** | Core totals are always numbers; none of the 546 parsed Form 990 filings in `_data/p990/` has an empty core total, so a 0 may mean "not reported". | A line missing from the return is stored as `null`, never 0, so "not reported" and zero can be told apart. |
| **Field names by form** | 990-EZ filings use some different names, such as `totcntrbs` instead of `totcntrbgfts` and `totnetassetsend` instead of `totnetassetend`. | The core totals use the same names for 990 and 990-EZ filings. |
| **Amended returns** | Shows the filing ProPublica processed. | Keeps the most recently processed filing, so an amended return replaces the original. The tool's maintainers found this to be the cause of every mismatch they saw with ProPublica. |
| **Detail** | About 70 summary fields per filing. | Line-level detail, such as expenses split by program, management and fundraising, officer pay, grants made, and related organizations, which ProPublica doesn't include. |

## Roadmap / Contributions Wanted

There are many other ways to programmatically scan 990 forms; the [Giving Tuesday 990 Infrastructure Project](https://990data.givingtuesday.org/) is the source `foss990parser` uses.

- [ ] Publish the IRS 990 data in this repository, as the `irs-990` dataset.
- [ ] Move both datasets to their `/api/v2/` paths, keyed by foundation identifier.
- [ ] Build charting/reporting by year/org for key finances.
- [ ] Linting and error checking.
- [ ] Automation to update 990s periodically, to find when orgs file new tax years.
- [ ] Build visualizations of contributions vs. sponsorship model income; especially comparing c3 to c6 orgs.

## International Nonprofit Tax Law

Nonprofit taxes vary by country, so Europe is quite complex when comparing different organizations.  While there aren't any completely similar structures in Europe as 501(c)(3)'s, there are some ways to measure equivalent kinds of tax and governance laws.

- [IRS Equivalency Determination](https://www.irs.gov/charities-non-profits/grants-to-foreign-organizations-by-private-foundations) - guidelines for determining if a specific non-US organization is similar enough to a (c)(3)
- [NGO Source](https://www.ngosource.org/) - an organization specializing in making equivalency determinations
- Council of Foundations has detailed reviews of NPOs, for [example in Germany](https://cof.org/content/nonprofit-law-germany)
- [Tertius](https://tertius-online.de/) - a Structured database of NPO laws and policies in Germany and EU

### International Nonprofit Tax Lookup

- EU wide https://e-justice.europa.eu/106/EN/business_registers_in_eu_countries?GERMANY&member=1
- UK https://register-of-charities.charitycommission.gov.uk/documentation-on-the-api Detailed reports available
- BE https://economie.fgov.be/en/themes/enterprises/crossroads-bank-enterprises/services-everyone/consultation-and-research-data/cbe-public-search Fairly detailed reports available
- NL https://www.kvk.nl/zoeken/handelsregister/?handelsnaam=NLNet&kvknummer=&straat=&postcode=&huisnummer=&plaats=&hoofdvestiging=1&rechtspersoon=1&nevenvestiging=1&zoekvervallen=0&zoekuitgeschreven=1&start=0  Various reports available for a fee
- DE https://www.unternehmensregister.de/ureg/?submitaction=language&language=en or https://www.handelsregister.de/ - includes various downloads, but no obvious finances
- AT Searches cost a fee https://www.justiz.gv.at/service/datenbanken/firmenbuch/

### International NPO Legal Types By Country

- [A simplistic listing in EU by Nordic HQ](https://www.nordichq.com/guides/list-of-legal-entity-types-by-country-in-europe/)
- [2009 research paper on detailed NPO laws in Europe](https://www.icnl.org/resources/research/ijnl/the-legal-framework-for-not-for-profit-organizations-in-central-and-eastern-europe)
- [Organizational and Legal Forms of Nonprofit Organizations in Central Europe, 2004](https://www.researchgate.net/publication/302041292_Organizational_and_Legal_Forms_of_Nonprofit_Organizations_in_Central_Europe)


### Notes on some EU Charities

Eclipse Foundation 0760.624.114 https://kbopub.economie.fgov.be/kbopub/toonondernemingps.html?ondernemingsnummer=760624114 Includes official list of directors "legal functions"

https://kbopub.economie.fgov.be/kbopub/zoeknummerform.html?nummer=0760.624.114&actionLu=Search also finds Eclipse basic record
table#toonfctie tr, then three tds = director/principal officer title, name, date

Eclipse bank record link: https://consult.cbso.nbb.be/consult-enterprise/0760624114 Includes links to download detailed finances, in French; offers PDF, CSV, or XBRL format downloads

Eclipse Foundation Europe Gmbh 0804.570.458 https://kbopub.economie.fgov.be/kbopub/toonondernemingps.html?ondernemingsnummer=804570458
