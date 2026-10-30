# Plans, research notes, and prompts

This directory records the prompts, plans, research, and decisions behind features of
this repository. It works as a partial roadmap, and as the place where agents and people
find decisions that were already made.

## File names

`{YYYY-MM-DD}-{short-title}.md`, where the date is the day the document was started and
the title is a few lowercase words joined by hyphens, for example
`2026-10-28-crosswalk-fields-evidence.md`.

## Each document starts with

```markdown
# Title in sentence case

YYYY-MM-DD · Author(s), e.g. "Shane Curcuru, with Claude"

Status: draft | decided | implemented in #NN | superseded by [other plan](file.md)

## Prompt

The request that started this work, quoted in the requester's own words.
```

Then whatever sections the work needs. Plans that ask maintainers to choose should end with
**Open questions**, and once they answer, a **Decisions** section that records each
answer and its date.

## Rules

- Keep maintainers' comments inline, marked with their initials, for example **SC:**.
- When a later document replaces an earlier one, update the earlier one's `Status:`
  line rather than deleting it.
- Link to code, data, and other plans with relative paths.
- Never include personal email addresses, tokens, or private links.
