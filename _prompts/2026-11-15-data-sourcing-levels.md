<!-- SPDX-License-Identifier: Apache-2.0 -->
# How we source each dataset, and how we store that sourcing

2026-11-15 · Shane Curcuru, with Claude

Status: draft

## Prompt

> Pause the foundation checker for now so we can review how we store the sourcing of
> data: We probably don't need full sources for all changes in _foundation models; data
> there is a different conceptual type and importance than attestations in the
> crosswalk.
>
> Start a new thread to briefly review all the datasets we track, and how the
> documentation in the site (both for humans and agents) describes how we verify sources
> in each case, and how we store data about sourcing. Review the following list of
> proposed changes/clarifications about how and why we record sourcing of different
> datasets.
>
> * _foundations data is mostly factual and fairly obvious for humans to do a good
>   enough "gut check" if any change is correct. It's also typically either read by
>   humans browsing the site, or by researchers doing general ecosystem work, so
>   potential errors are not as critical.
> * Tax data is primarily copied directly from government or trusted sources (like
>   ProPublica), so the only sourcing needed is when and how we copied the data.
> * Sponsorship models and Sponsors data is meant to enable roughly comparing
>   foundations, since our modeling can only be approximate given the variation and
>   limited information some foundations provide; sourcing mostly needs the dates and how
>   we captured each scan of a foundation pages. We should ensure each webpage describing
>   these models explains the level of approximation.
> * Parts of the Crosswalk data we record is different in several ways: Many of the
>   relationships are factual and can be derived; however accuracy is most important
>   here because some of the relationships are meant to represent official
>   organizational ownership of repo/package namespaces; users of this data likely expect
>   a much higher level of accuracy and human checking than other datasets.
>
> Crosscheck the documentation and propose a PR updating "how we source data and how we
> store that sourcing" any pages needed. Ensure we verify that human-facing docs have the
> same meaning as agent-facing docs (and link directly to each other when there are
> similar sections).

## Review: what the docs said before this change

The same rule was written for every dataset: [AGENTS.md](../AGENTS.md#data-rules) ("each
new or changed fact needs a URL you actually checked ... and the date you checked it
where the schema has a field for it"), [CONTRIBUTING.md](../CONTRIBUTING.md#rules-for-data)
("every new or changed fact needs a URL you actually checked"), and
[Data Philosophy](../_pages/data.md) ("every fact should trace to a source we checked").
What each dataset actually stores, as of this review:

| Dataset | Sourcing stored | Gap against the old docs |
| --- | --- | --- |
| `_foundations/` (96), `_entities/` | None per field; the foundations schema has no source or check-date fields | CONTRIBUTING called recording check dates "an open design question", and fdnmodel listed "verifying and dating existing records" as a need. |
| `_data/projects-*.csv` | None; scraper code and git history | Not mentioned. |
| `_data/p990/`, `_data/taxes/uk-*.json` | ProPublica's `data_source` and `api_version`; UK `data_source` and `parseDate`; no download date in ProPublica files, only the git commit | The "URL you checked" rule doesn't fit copied data, and no page said how the copy is recorded. |
| `_sponsorships/` (39) | `levelurl`, `sponsorurl`, `effectiveDate`; `sources:` lists where past sponsor lists are found (26 files) | Fine. |
| `_data/sponsorships/`, `history/sponsorships/` | Current lists: `parseDate` (none of 37 files has `lastChecked` yet, since the tool started writing it after they were last updated). History: `parseDate`, `lastChecked`, `source`, `ref` for each recorded list | The sponsorships page says current lists hold `lastChecked`; true for the tool, not yet for the committed files. |
| `_sponsors/` (36) | Required `sources` (URL, `observed`, `detail` per value), `lastReviewed`, `reviewedBy` | Heavier than the proposal above; see open question 1. The page had no note on approximation. |
| `_data/crosswalk/` (31 links) | Evidence per link: `type`, `source`, `observed`, `creator`; optional `lastReviewed` and `reviewedBy`, filled on none | The page said nothing about why this dataset needs more care, or that probable links are not proof of ownership. |

The sponsorship pages and foundation page includes already said that money figures are
estimates, but not why or how rough they are.

## Changes in this PR

- New [How We Source Data](../_pages/data.md) section (`/data#sourcing`): one table
  with each dataset's accuracy needs, how changes are checked, and what sourcing is
  stored where, following the four points above.
- [CONTRIBUTING.md](../CONTRIBUTING.md#rules-for-data) and
  [AGENTS.md](../AGENTS.md#data-rules) say the same per-dataset rules, and both link
  to that section and to each other.
- New sections: `/sponsorships#accuracy` (how approximate, and how scans are recorded),
  `/sponsors#accuracy`, `/taxes#sourcing`, `/crosswalk#accuracy`; a line on the
  foundation model page.
- No schema, data, or tool changes.

## Open questions

1. **`_sponsors/` sources.** The schema requires a source and date for each value,
   plus `lastReviewed`. These are lookup identifiers (LEI, CIK, Wikidata) that join to
   other registries, so the recommendation is to keep them as they are, even though
   the rest of the sponsorship data needs only scan dates. Keep, or relax?
2. **ProPublica download date.** The date we copied each `_data/p990/` file is only in
   git history, which researchers reading the raw file don't see. Is git history
   enough, or should `foundation_reporter` write a retrieved date (for example into
   `foundations_990_common.csv` or a small manifest)? Recommendation: git is enough for
   now.
3. **Crosswalk review fields.** For the dataset that needs human checking most,
   `lastReviewed` and `reviewedBy` are optional and unused. Should they become required
   on every link (a schema change)? Recommendation: yes, filled when a maintainer
   reviews each link.
4. **`stewards.jsonl` and probable links.** The bulk export includes probable links.
   The docs now tell users to filter on `confidence`. Should the export instead hold
   only confirmed links (an API shape change)? Recommendation: keep as is, with the
   new note.
5. **Foundation checker plan (draft PR #97).** With foundation records needing no
   per-field sources, the recommendation is to drop the proposed per-foundation
   evidence files and let each checker PR's description, which lists what it fetched,
   be the record.
