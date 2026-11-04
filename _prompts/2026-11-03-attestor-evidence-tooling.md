# Tooling for attestors to add evidence

2026-11-03 · Shane Curcuru, with Claude

Status: decided; items 1, 2 and 5 implemented in #90; items 3 and 4 are future questions for maintainers

## Prompt

> Add a separate question/task for the future if you recommend additional automated tools
> to help that workflow (rather than manually copying attestation blocks).

"That workflow" is the attestor workflow now documented on
[`/crosswalk#attestor-workflow`](../_pages/crosswalk.md): an attestor confirms a link out of
band, makes a person record with `fdncrosswalk add-person`, copies the printed
`confirmedWith` block into a `human-attested` evidence item in
`_data/crosswalk/<foundation>.json` by hand, then validates, exports, and opens a pull request.

## Problems with the manual workflow

- **Hand-copied JSON.** The attestor copies `confirmedWith` and types `type`, `creator`,
  `method`, `observed`, and `detail` into the right account or package. Typos in a login or
  identifier are caught by `validate` only if they break the schema; a wrong but valid
  `creator` silently drops the confidence to probable.
- **`source` is circular.** `source` should be the pull request that records the
  attestation, but its URL exists only after the pull request is opened, so attestors need
  a second commit.
- **Renewals are easy to miss.** Attestations go [stale](../_pages/crosswalk.md) after one
  year, and nothing reminds the attestor.
- **Exports are easy to forget.** The crosswalk and its exports must be committed together.

## Recommended tools

1. **`fdncrosswalk attest`**, a guided command alongside `add-person`. It would ask which
   foundation, then list that foundation's accounts and packages to pick from (or accept
   `--account github.com/apache` / `--purl pkg:pypi/numpy`); ask for the method, observed
   date, and a one-sentence detail; reuse an existing person identifier or run the
   `add-person` questions inline; take `creator` from an argument or the git
   configuration and warn if it is not in `_data/attestors.json`; then add the evidence
   item, validate, and run `export`. It writes only to the public crosswalk file, and
   private records still go only to the private repository.
2. **`fdncrosswalk attest --renew`**, which lists the attestor's own `human-attested`
   items that are stale or will be within 60 days, and, after the attestor confirms each
   one again, updates `observed` in place, keeping the same identifier.
3. **Fill `source` automatically.** Either let `source` be left as a placeholder that a
   small step in CI replaces with the pull request URL, or accept the commit as the
   source. Either way needs a maintainer decision (see below), and a CI step would be a
   new GitHub Actions workflow, which needs approval under `AGENTS.md`.
4. **An issue form for foundations.** A GitHub issue form, "Confirm our accounts", that a
   foundation officer can fill in to list accounts and ask an attestor to confirm them,
   so requests arrive in a consistent shape.
5. **A stale-attestation report.** Add the stale `human-attested` items, grouped by
   attestor, to `fdncrosswalk report`, so a monthly review can ping each attestor.

Items 1, 2 and 5 are changes to the existing `fdncrosswalk` tool and need no new
dependencies. Items 3 and 4 add GitHub configuration. **SC:** Complete items 1, 2, and 5 now in this PR.  Add a Future Questions For Maintainers item with a brief description of the plan to implement items 3 and 4 so that maintainers can provide feedback on how to add GitHub automations later.

## Open questions

1. Build `fdncrosswalk attest` (and `--renew`) as recommended, or keep the manual
   workflow for now while there are few attestors? **SC:** Yes, please build the new fdncrosswalk features here.
2. For `source`, keep the pull request URL (needs a follow-up commit or a CI step), or
   allow a placeholder or the commit URL? **SC:** Allow a placeholder; add a Future Questions For Maintainers about deciding changes here later.
3. Should `_data/attestors.json` record each attestor's own organization and role
   (for example `memberOf` and `roleName`, as in the person records)? Today that
   connection is recorded only in the pull request that added them. This is a schema
   change. **SC:** Yes, add these entries, however make them optional; some attestors may not be directly associated with a foundation listed here; some may be associated with an entity or some other non-foundation project.
4. When an attestor is themselves an officer of the foundation whose account they
   confirm, should `confirmedWith` point to their own person record, or should a
   different evidence type or method be used? **SC:** confirmedWith can point to their own record if appropriate; also add a type of method for the consent recorded that is "self", for cases where an attestor is the person adding themselves.
5. Can attestors who are not maintainers create private person records, given that only
   maintainers can read the private repository? The documented workflow has them send
   the person's details to a maintainer. **SC:** No, only fossfoundation maintainers can add data to the private repository; maintainers of this project are central to the trust model of that private data, and trust or confirmations there can come out of band or via other communication channels.

## Decisions

Shane answered on 2026-11-04, inline above (**SC:**).

1. **Build `fdncrosswalk attest`, `attest --renew`, and the renewal list in `report`**
   (items 1, 2 and 5) in #90. As built: `attest <foundation>` takes `--target` and
   `--creator` or asks for them; the creator comes from `--creator` or a question, not the
   git configuration, because a git user name is not always a GitHub login. `report` also
   lists evidence whose source is still pending.
2. **`source` may be the placeholder `pending`** until the pull request that records the
   attestation exists. The crosswalk schema allows it, `attest` uses it by default,
   `report` lists it, and the JSON-LD exports leave a pending source out, since it is not
   an IRI. How to fill it in later is a future question below.
3. **`_data/attestors.json` gains optional `roleName` and `memberOf`.** They are optional
   because some attestors are not directly associated with a foundation listed here; some
   are associated with an entity or another project. `memberOf` is a `_foundations` or
   `_entities` identifier, or the website URL of an organization not listed;
   `fdncrosswalk validate` checks it.
4. **`confirmedWith` may point to the attestor's own person record** when the attestor is
   the officer who confirms the link. The consent `method` in person records gains the
   value `self`, for an attestor recording their own details.
5. **Only maintainers of this project add data to the private repository.** "Maintainers
   of this project are central to the trust model of that private data, and trust or
   confirmations there can come out of band or via other communication channels." Other
   attestors send a person's details to a maintainer, who creates the record.

## Future questions for maintainers

These need maintainers' feedback before any GitHub automation is added, since a new
workflow needs approval under `AGENTS.md`.

- **Filling in `source` (item 3).** Proposed plan: a small GitHub Actions job runs on pull
  requests that change `_data/crosswalk/`. It finds `human-attested` items whose source is
  `pending` and either (a) comments on the pull request with the exact lines to change, or
  (b) after merge, opens a follow-up pull request that replaces `pending` with the merged
  pull request's URL and regenerates the exports. Option (a) needs no write access; (b) needs
  a token that can push a branch. Alternatives: keep `pending` and accept the git history
  as the record, or allow the commit URL instead. Which, if any?
- **An issue form for foundations (item 4).** Proposed plan: a `.github/ISSUE_TEMPLATE`
  form, "Confirm our accounts", with fields for the foundation identifier, the accounts or
  packages to confirm, the requester's role, and how they prefer to be contacted (with a
  reminder not to post personal emails publicly). A maintainer or attestor then confirms
  out of band and runs `fdncrosswalk attest`. Should requests come through public issues,
  or only through a private channel?
