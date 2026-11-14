# Structured World directory entry

2026-11-14 · @polaz, with Codex

Status: decided

## Prompt

From [the request in #94](https://github.com/Punderthings/fossfoundation/issues/94):

> May I prepare a minimal PR adding Structured World as `_foundations/structuredworld.md`, including a neutral one-sentence description?

## Decisions

2026-11-14, [maintainer approval](https://github.com/Punderthings/fossfoundation/issues/94#issuecomment-6879583997):

**SC:** "Yes, as long as Structured World is a legally recognized non-profit, please submit a PR to add it. Use your CIF of `55841868` as the taxID value."

**SC:** "To clarify: the _foundations dataset should be licensed APACHE-2.0"

Add only the [foundation record](../_foundations/structuredworld.md) and this decision note. The entire new record, including its original descriptive sentence, is Apache-2.0. This does not change the licenses of the source websites or the association's projects.

## Sources and field choices

Public sources checked on 2026-11-14:

- [About](https://sw.foundation/about) and [Romanian legal details](https://sw.foundation/ro/about): name, Romanian nonprofit association, Bucharest, contact page and legal personality from 9 October 2026. The special register entry is no. 102 of that date at Judecătoria Sectorului 4 București; the national register number is 3810/A/2026.
- [Romanian statute](https://sw.foundation/ro/statute), articles 1-4 and 7-8: legal name, nonprofit form, location and mission. The [English translation](https://sw.foundation/statute) is a reference; the Romanian original prevails.
- [Governance](https://sw.foundation/governance): board information and a further reference to the registration date.
- The maintainer's linked comment: public source for CIF `55841868` and its use as `taxID`.

The schema defines `foundingDate` as legal incorporation or similar, so use the string `2026-10-09`, when legal personality began, rather than the court decision date of 23 September. `București` identifies the municipality in `addressRegion`; no street address is included.

[Schema.org NonprofitType](https://schema.org/NonprofitType) has no Romanian category. Use the required empty string for `nonprofitStatus`, as CONTRIBUTING permits, rather than a foreign tax classification or YAML null.

The website is listed as the organization's public information site. About explicitly says it is still operated personally and has not been transferred to the association. The record makes no website-ownership claim and does not list projects, services, funding, staff or a special public-benefit legal status.

## Validation plan

Validate the front matter against [the current schema](../_data/foundations-schema.json), build with the pinned Ruby version using `bundle exec jekyll build`, inspect the rendered record and its links, and run `uvx reuse lint`. Do not change dependencies, workflows or generated datasets.
