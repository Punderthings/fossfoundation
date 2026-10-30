# Site documentation consistency

2026-10-30 · Shane Curcuru, with Claude

Status: decided; implemented in the PR that adds this file

## Prompt

> We are continuing to improve the documentation explaining what the site is for, how and
> what kinds of data we store, and how humans can submit PRs or issues to our project,
> either with agents or by themselves.
> Review CONTRIBUTING.md, and the following _pages (data.md, research.md, workflow.md, and
> especially fdnmodel.md "Foundations Model Overview") and suggest any improvements, and
> especially propose changes to keep the documentation consistent.

## Findings

- [CONTRIBUTING.md](../CONTRIBUTING.md) allowed MIT contributions and linked a `NOTICE`
  file that does not exist, conflicting with [AGENTS.md](../AGENTS.md) and
  [REUSE.toml](../REUSE.toml).
- No page stated the project's scope.
- [data.md](../_pages/data.md) and [fdnmodel.md](../_pages/fdnmodel.md) described schemas
  and OpenAPI as future plans, although both exist; data.md omitted the crosswalk.
- [workflow.md](../_pages/workflow.md) had wrong paths (`_foundation/`,
  `foundations/list.json`) and no `BUNDLE_GEMFILE` for the Ruby tools.
- The research layout linked to a missing anchor, `/data#foss-foundations-inclusion-criteria`.
- AGENTS.md described `_entities/` as commercial sponsors; entities.md defines them as
  projects that are not legal corporations, usually with a fiscal host.
- data.md and fdnmodel.md opened with the same paragraph; "Foundation" was capitalized
  inconsistently, and UK and US spellings were mixed.

## Decisions

All answered by Shane on 2026-10-30.

1. **Licensing.** Code and prose Apache-2.0; new datasets and data exports CC0-1.0;
   existing data Apache-2.0 until maintainers decide otherwise. MIT and the `NOTICE` link
   are dropped.
2. **Scope.** The site records organizations, the people who lead them, and how they are
   funded. "Data about code, packages, repositories, and similar technical details is left
   to ecosyste.ms and similar services." **SC:** agreed for now; expect this to get more
   detailed as maintainers are added.
3. **Sourcing.** Use the AGENTS.md wording everywhere.
4. **Descriptive text.** Officers of a foundation get a say. **SC:** data updates about
   organizations will often come from an updated web scraping run, or from members of
   that organization who tell us directly of changes (or, rarely, correct our data
   directly).
5. **Inclusion criteria.** Add the scope bullet and point `nonprofitStatus` at
   Schema.org NonprofitType.
6. **Schemas, API and tooling.** Describe what exists now. **SC:** schemas, API, and
   tooling each get detailed documentation in their own area, linked to each other where
   relevant.
7. **Citations.** **SC:** notes about citations, and being able to provide them in the
   future, are important for every dataset.
8. **AGENTS.md** entities line fixed in the same PR; one PR overall, one commit per file.

## Left for later

- [sponsorships.md](../_pages/sponsorships.md) still calls its files `foundation.md`.
- Citation metadata for each dataset (for example `CITATION.cff` or Schema.org `Dataset`).
- How to record when each field of a record was last verified.
