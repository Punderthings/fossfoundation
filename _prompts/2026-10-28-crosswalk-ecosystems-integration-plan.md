# Crosswalk ↔ ecosyste.ms integration and evidence confidence plan

2026-10-28 · Shane Curcuru, with Claude

> Converted from a Claude Docs plan document on 2026-10-28. Comments from Shane Curcuru are kept inline (marked **SC:** or **Shane:**). Links to the other plan documents point to their copies in this directory; patch files mentioned (`0001`–`0003`) were saved outside the repository while Claude had no push access.

## Prompt

Shane, 2026-10-28:

> Start a new thread to review the Foundation namespaces on forges and registries documentation and plan.
>
> * Propose more specific ways that fields and evidence for the data we store in the crosswalk can be used or can reference the data in ecosyste.ms, with an eye for how we can integrate or at least have simple APIs that can share data with ecosyste.ms datasets.
> * Plan an update process and additional "evidence data confidence" so that humans can periodically update any connections between foundations and their repos/packages/releases, and add an optional "human-prooved" or similar value to evidence. The leadership of core foundations have personal trust between individuals, and some confirmations of ownership can be verified out-of-band by a trusted human and stored.
>
> ask questions to direct research or suggest more specific choices for what kinds of fields we use to connect, or specific names for fields. Also remember we prefer to use schema.org, Dublin Core, or other well-known data taxonomy or naming standards.

Shane's follow-up in the thread (decision 6 below):

> For human-attested store the persons name, email address, role at organization and the date done; this specific case relies on personal connections so needs to store the name (which is optional and can be skipped)

Shane's other answers are inline in the Decisions table and the quoted IMPORTANT / NEW TASK notes after it.

## Summary

**Status, 28 Oct 2026 afternoon:** steps 1 and 2 are built to Shane's choices and saved as `crosswalk/0003-ecosystems-links-attestations-exports.patch` in project files (applies after 0001 and 0002; 40 tests pass). The plan for private attestor data, the new task, is at the end of this doc. Sections below are the original proposal; where the build differs, a note says so.

The crosswalk's account-plus-evidence design is sound, and three additions would make it join cleanly with ecosyste.ms and support trusted human confirmations: a stable platform id on each account, a new package list keyed by purl, and a `human-attested` evidence type with review dates. Nothing here is implemented yet; each choice is listed in Decisions at the end with a recommended option.

Good news from today: ecosyste.ms is now reachable from this environment, so the field names below were checked against live records and the published OpenAPI specs (all calls used `mailto=` a polite email). For example, the ecosyste.ms owner record for `apache` carries `uuid: 47359`, which is GitHub's numeric org id, and numpy's package record serves a CodeMeta (schema.org `SoftwareSourceCode`) view.

What the plan proposes, in short:

1. **Join keys that match ecosyste.ms exactly**: keep `platform` + `name`, add the platform's stable `identifier`, and add a `packages` list using purl (`identifier`) and `codeRepository`, the same names CodeMeta and ecosyste.ms already use.
2. **A small sharing API**: static JSON-LD per foundation, plus one flat JSONL feed with ecosyste.ms column names, so ecosyste.ms can ingest "which foundation stewards this owner or package" without a mapping step.
3. **Evidence that ages and can be vouched for**: a `human-attested` evidence type backed by a list of trusted attestors, schema.org `lastReviewed` / `reviewedBy` on each account, and a `stale` confidence level when evidence is old.
4. **A refresh loop**: a monthly GitHub Action re-checks evidence and proposes new candidates from ecosyste.ms as a pull request; people review quarterly and renew attestations yearly.

## Review of the existing work

The survey ([Foundation namespaces on forges and registries](2026-10-28-foundation-namespaces-survey.md)), the field doc ([Crosswalk fields and evidence across registries](2026-10-28-crosswalk-fields-evidence.md)) and patches 0001 and 0002 hold up well. The generic `accounts[]` + `evidence[]` shape, computed confidence, and keeping rejected look-alikes (npm `@psf`) are the right calls, and the pilot data checks out against live ecosyste.ms records.

What a live check against ecosyste.ms adds:

| Finding | Checked | What it means for the schema |
| --- | --- | --- |
| Owner `uuid` is the platform's numeric id: apache = 47359, python = 1525981 | [repos owner apache](https://repos.ecosyste.ms/api/v1/hosts/GitHub/owners/apache) | Store it; it survives org renames, as the OpenSSF trusted-publisher guidance asks |
| Owner records have `website`, `metadata.funding` and `has_sponsors_listing`, but no GitHub Verified flag | same | `platform-verified` still has to come from GitHub itself; worth asking ecosyste.ms to add `is_verified` |
| npm `@openjs` namespace exists with `packages_count: 0` | [packages namespace @openjs](https://packages.ecosyste.ms/api/v1/registries/npmjs.org/namespaces/@openjs) | Matches the pilot note; namespaces alone miss most foundation packages |
| PyPI packages have `namespace: null`; PyPI orgs are not modelled | [packages numpy](https://packages.ecosyste.ms/api/v1/registries/pypi.org/packages/numpy) | PyPI links must go through package purls, not an account lookup |
| `packages/lookup?repository_url=` returns every package built from a repo (100+ for apache/opendal across cargo, npm, nix) | [lookup opendal](https://packages.ecosyste.ms/api/v1/packages/lookup?repository_url=https://github.com/apache/opendal) | The cheapest way to discover a foundation's packages from its confirmed orgs |
| Package records serve CodeMeta 3.0 with `identifier: pkg:pypi/numpy` and `codeRepository` | [numpy codemeta](https://packages.ecosyste.ms/api/v1/registries/pypi.org/packages/numpy/codemeta) | Use the same schema.org names in our package entries |
| Papers project numpy has `czi_id: SM3411`, `mentions_count: 832`, last synced Nov 2023 | [papers numpy](https://papers.ecosyste.ms/api/v1/projects/pypi/numpy) | Papers joins on ecosystem + package name; its data is old, so treat counts as a snapshot |
| Sponsors account numfocus: 345 sponsors, 64 active | [sponsors numfocus](https://sponsors.ecosyste.ms/api/v1/accounts/numfocus) | Joins on the GitHub login we already store |

Gaps in the current schema:

- **No stable id** on accounts, only the login, so a renamed or re-registered org would silently match.
- **No package or release entries.** The crosswalk says which accounts a foundation controls, but not which purls or repositories, which is what papers, CRA attestations and ecosyste.ms all key on.
- **`source` is a required URL**, which blocks out-of-band confirmations that have no public page.
- **Evidence never ages.** Confidence ignores `observed`, so a 2026 check still counts as confirmed in 2030.
- **Evidence does not say who checked it**, a person or the probe tool.
- `ecosystems.py` returns nothing for PyPI accounts and does not build papers or `packages/lookup` URLs yet. Self-hosted forges are passed as a bare hostname, which is right: the ecosyste.ms host list names them `gitlab.eclipse.org` and `gitlab.gnome.org`.

## Proposed linking fields

*As built:* accounts use `platformId` (decision 1b), and packages are keyed by `purl`; both map to `schema:identifier` in the JSON-LD context, so the foundation `identifier` keeps its single meaning. `sameAs` is not stored; the export adds the ecosyste.ms page link.

Add three optional fields to accounts and one new list of packages; every new name comes from schema.org, CodeMeta or Dublin Core, and every value matches what ecosyste.ms returns so no translation table is needed.

**New on `accounts[]`**

| Field | Vocabulary | Value | ecosyste.ms field it joins to | Example |
| --- | --- | --- | --- | --- |
| `identifier` | schema.org `identifier` | The platform's stable id, as a string | repos owner `uuid`; packages maintainer `uuid` | `"47359"` for github.com/apache |
| `sameAs` | schema.org `sameAs` | Other URLs for the same account, such as its ecosyste.ms page | owner `html_url` | `https://repos.ecosyste.ms/hosts/GitHub/owners/apache` |
| `lastReviewed`, `reviewedBy` | schema.org (on `WebPage`, reused here) | Date and person of the last human review of this account | none | see the evidence section |

The existing `platform` and `name` stay as the join key: `platform` maps to the ecosyste.ms host (`github.com` → `GitHub`) or registry name (`pypi.org`), and `name` to the owner `login` or namespace `name`.

**New `packages[]` list (per foundation file)**

Each entry says "this package or repository belongs to this foundation or project", with its own evidence. It covers the PyPI case, where ecosyste.ms has no org or namespace record.

| Field | Vocabulary | Required | Meaning | Example |
| --- | --- | --- | --- | --- |
| `identifier` | schema.org `identifier`, value is a purl (ECMA-427) | yes | Package or repo, without version | `pkg:pypi/numpy`, `pkg:github/apache/kafka` |
| `codeRepository` | schema.org / CodeMeta | no | Source repository URL | `https://github.com/numpy/numpy` |
| `account` | local | no | `platform/name` of the account it is published under | `github.com/numpy` |
| `project` | local, as today | no | Hosted project id | `numpy` |
| `evidence[]` | as today | yes | Why it belongs | `publish-provenance` from the PyPI attestation |

Releases are not listed one by one, since ecosyste.ms already tracks versions. A specific release appears only as the thing an evidence item is about, through a new optional `evidence[].about` holding a versioned purl such as `pkg:pypi/pyperf@2.10.0`. That gives release-level proof (a provenance record, a CRA attestation) without copying release lists.

**Foundation-level ids (on the foundation record, from the handoff)**

Keep `wikidataId`, and add `rorId` (Research Organization Registry) for OpenAlex and papers, `openCollectiveSlug` for fiscally hosted projects, and `githubSponsors` only if it differs from a confirmed GitHub account login. All three are optional.

**Mapping existing evidence fields to standard terms**

The JSON keys stay short; the JSON-LD context (next section) maps them so the export reads as standard vocabulary.

| Our key | Standard term | Why this one |
| --- | --- | --- |
| `evidence[].type` | `dcterms:type` | Dublin Core's generic classifier |
| `evidence[].source` | `dcterms:source` / `prov:wasDerivedFrom` | Where the claim came from |
| `evidence[].observed` | `prov:generatedAtTime` (or `dcterms:date`) | When it was last seen true |
| `evidence[].detail` | `dcterms:description` | Free text |
| `evidence[].creator` (new) | `dcterms:creator` / `prov:wasAttributedTo` | Who recorded it: a person's GitHub login, or `fdncrosswalk/<version>` for the probe |
| `evidence[].about` (new) | `schema:about` | The release or package the evidence is about |
| account `platform` + `name` | `schema:identifier` pair | Matches ecosyste.ms host + login |

W3C PROV-O fits the evidence model best, since each evidence item is a provenance statement about a claim. Schema.org has `ClaimReview`, but it is built for fact-checking articles and would be a stretch here.

## Sharing data with ecosyste.ms

Publish three static files from the Jekyll build, all read-only and served from the site like the existing `openapi/v1` paths; no server is needed.

| File | Shape | Who it is for |
| --- | --- | --- |
| `/api/v1/crosswalk/<identifier>.json` | The crosswalk file plus computed `confidence` per account and package | Anyone browsing one foundation |
| `/api/v1/crosswalk/context.jsonld` | JSON-LD context mapping our keys to schema.org, Dublin Core and PROV-O | Linked-data users; makes the files above valid JSON-LD |
| `/api/v1/crosswalk/stewards.jsonl` | One flat line per confirmed or probable link, named the way ecosyste.ms names things | ecosyste.ms ingestion and bulk joins |

A `stewards.jsonl` line would look like this, with column names copied from ecosyste.ms (`host`, `login`, `uuid`, `registry`, `namespace`, `purl`) so they join with no mapping:

```json
{"host":"GitHub","login":"apache","uuid":"47359","steward":"asf","stewardName":"The Apache Software Foundation","stewardWikidata":"Q489709","confidence":"confirmed","lastReviewed":"2026-10-28"}
{"registry":"pypi.org","purl":"pkg:pypi/numpy","codeRepository":"https://github.com/numpy/numpy","steward":"numfocus","project":"numpy","confidence":"probable","lastReviewed":"2026-10-28"}
```

The Wikidata id above is illustrative; the export would read it from the foundation record.

Why this shape: ecosyste.ms has bulk endpoints (`/purls/bulk_lookup`, `/packages/bulk_lookup`) and keys owners by host + login, so a file of those keys plus a steward column is the smallest thing Andrew Nesbitt could load. It also lets us run the reverse: send our purls to `bulk_lookup` and get back current metadata without storing any of it.

What to ask ecosyste.ms for, in one issue or email:

1. Would they ingest `stewards.jsonl` and show "Steward: The Apache Software Foundation" on owner and package pages?
2. Could owner records carry GitHub's `is_verified` flag? It would turn many of our `profile-claim` checks into `platform-verified` at scale.
3. Would they accept the CodeMeta property for this link? CodeMeta has no steward term, so the nearest is schema.org `publisher` or `sponsor` on `SoftwareSourceCode`; see Decisions.

The export stays identifiers and our own judgements only. Stars, downloads and mention counts stay in ecosyste.ms (CC-BY-SA-4.0), fetched when needed.

## Evidence confidence and human attestation

Add a tenth evidence type, `human-attested`, that reaches "confirmed" only when the person recording it is on a short list of trusted attestors, and let confidence drop to `stale` when the newest supporting evidence is too old.

**The `human-attested` evidence type**

It records that a trusted person confirmed the link out of band, usually with someone in the foundation's leadership they know personally. The proof is the signed commit or reviewed pull request that adds it, so `source` can be that PR's URL instead of a public page.

| Field | Vocabulary | Required for this type | Meaning | Example |
| --- | --- | --- | --- | --- |
| `type` | `dcterms:type` | yes | `human-attested` |  |
| `creator` | `dcterms:creator` | yes | GitHub login of the attestor; must appear in `_data/attestors.json` | `ShaneCurcuru` |
| `method` | `schema:measurementTechnique` | yes | How it was confirmed: `in-person`, `video-call`, `email-official-domain`, `signed-message`, `foundation-ticket` | `video-call` |
| `confirmedWith` | `schema:Person` | yes | The person at the organization who confirmed the link | object, fields below |
| `confirmedWith.name` | `schema:name` | no | Their name; may be left out | `Jane Example` |
| `confirmedWith.email` | `schema:email` | yes | Their email address | `jane@example.org` |
| `confirmedWith.roleName` | `schema:roleName` (`OrganizationRole`) | yes | Their role at the organization | `VP Infrastructure` |
| `confirmedWith.memberOf` | `schema:memberOf` | no | Organization the role is at; defaults to this crosswalk's foundation | `asf` |
| `source` | `dcterms:source` | yes | URL of the PR or signed commit that recorded it | a GitHub PR URL |
| `observed` | `prov:generatedAtTime` | yes | Date the confirmation was done | `2026-10-28` |
| `validThrough` | `schema:validThrough` | no | When it should be renewed; defaults to `observed` + 1 year | `2027-10-28` |
| `detail` | `dcterms:description` | no | One sentence |  |

These confirmations rely on personal connections between foundation leaders, so the record names who confirmed it where possible: name (optional), email, role and date. The `confirmedWith` shape is the same Person + `OrganizationRole` shape proposed for the leadership dataset, so the two can link later. One caution: the repo is public, and the leadership review flagged stored emails as a concern, so each person should agree to their email being recorded.

**The attestor list, `_data/attestors.json`**

A small file of people whose attestations count, each with `name`, `sameAs` (GitHub, ORCID), `dateAdded`, and an optional signing key fingerprint. It shares the person shape from the leadership work. Adding someone to it is itself a reviewed PR. An attestation by someone not on the list still counts, but only as `probable`.

**Confidence levels, updated**

Confidence stays computed, never typed. The rules, in order:

1. Any `contradiction` gives `rejected`, unless a later `human-attested` item says `"supersedes": true` and explains why in `detail` (for example, an org that changed hands back to the foundation).
2. `steward-declared`, `platform-verified` or `human-attested` by a listed attestor gives `confirmed`.
3. `profile-claim`, `program-badge`, `publish-provenance`, `repository-link` or `namespace-convention` gives `probable`.
4. Only `name-match` gives `unconfirmed`.
5. If every item that set the level is older than its freshness window, the level becomes `stale` and the account goes into the review queue. It still appears in exports, with its last good level beside it.

Proposed freshness windows: 90 days for anything a probe can re-check automatically, 1 year for `human-attested` and `steward-declared`, and no expiry for `contradiction`.

**Account-level review fields**

`lastReviewed` and `reviewedBy` (both schema.org) record the last time a person looked at the whole account, separate from any single evidence item. A review that finds nothing new updates these two fields only, which keeps diffs small.

## Update process

A monthly GitHub Action does the mechanical re-checking and proposes changes as one pull request; people only review, attest, and merge. The Action has to live in the fossfoundation repo, since this environment cannot push there.

*(Diagram not reproduced here: crosswalk refresh loop, 3 automated steps and 3 human steps, described below.)*

The Action never edits `accounts[]` or `packages[]` directly. It refreshes `observed` dates on evidence it could reproduce, and writes everything else to a review queue.

**What the Action does each month**

1. **Re-check:** for each evidence item with a machine-readable `source` (GitHub org page, Docker Hub org, PyPI provenance, npm registry JSON), fetch it again. If it still holds, set `observed` to today. If it no longer holds, leave the item and add a queue entry.
2. **Detect renames:** compare each account's stored `identifier` with the ecosyste.ms owner `uuid`, and check repository `previous_names`. A changed id for the same login is flagged as a possible re-registration.
3. **Find candidates:** for each confirmed forge account, call ecosyste.ms `owners/{login}/repositories`, then `packages/lookup?repository_url=` for each repo. Packages not yet in `packages[]` become candidates with `repository-link` evidence pre-filled.
4. **Open one PR** per run, with a summary table: refreshed, newly stale, new candidates, and contradictions found.

The queue lives in `_data/crosswalk-queue/<identifier>.json`, so pending suggestions never appear in exports.

**What people do**

| Task | Who | When | Output |
| --- | --- | --- | --- |
| Review the monthly PR | any maintainer | monthly | Merge refreshed dates; accept or drop candidates |
| Review each pilot foundation | a maintainer | quarterly | Update `lastReviewed` / `reviewedBy` per account |
| Out-of-band confirmation | a listed attestor | when a link is stale, contested, or newly added with only `probable` evidence; renew yearly | A `human-attested` evidence item in a signed commit |
| Trigger review | whoever notices | on an org rename, a namespace transfer, or a leadership change in the leadership dataset | Queue entry |

Every ecosyste.ms call in the Action carries `mailto=` a polite email. At about 5 pilot foundations and a few hundred repos, one run stays well under a thousand requests.

## Decisions for Shane

Each row has a recommended option; reply with the row number and a letter, or comment on the row. I will not change the schema or tool until you pick.

| # | Question | Options | Recommended |
| --- | --- | --- | --- |
| 1 | Name of the stable platform id on accounts | (a) `identifier`, schema.org; (b) `platformId`; (c) leave it out | (a): standard name, and ecosyste.ms already returns the value as `uuid` **Shane:** *Use (b), because existing users of our data may refer to a \_foundations/\<identifier>.json identifier: field (which should not be changed in our work)* |
| 2 | Where package links live | (a) new `packages[]` in each crosswalk file; (b) `purl` and `codeRepository` columns in `projects-*.csv`; (c) both: CSV for the project's main purl, crosswalk for evidence | (c): the CSVs stay simple and the crosswalk holds the proof *(c) agreed* |
| 3 | How releases appear | (a) `evidence[].about` with a versioned purl; (b) a `releases[]` list; (c) not at all | (a): proof per release without copying ecosyste.ms version lists *(a) agreed* |
| 4 | Name of the new evidence type | (a) `human-attested`; (b) `steward-attested`; (c) `peer-attested`; (d) `human-proved` | (a): "attested" matches CRA and SLSA wording; (b) wrongly suggests the foundation itself signed *(a) agreed* |
| 5 | Whose attestations reach "confirmed" | (a) people listed in `_data/attestors.json`; (b) anyone with a signed commit; (c) anyone | (a): mirrors the personal trust between foundation leaders you described *(a) agreed* |
| 6 | What is recorded about the person confirmed with | Decided by Shane on 2026-10-28: name (optional), email, role at the organization, and date | Done |
| 7 | Can a human attestation override a `contradiction`? | (a) yes, with `supersedes: true` and a reason; (b) no, a contradiction must be removed by PR | (a): orgs do change hands back, and the reason stays on record *(a) agreed* |
| 8 | Freshness windows before `stale` | (a) 90 days automated, 1 year human and steward; (b) 1 year for everything; (c) no expiry, show dates only | (a) *(a) agreed* |
| 9 | Standard term for "foundation stewards this package" in JSON-LD | (a) `schema:publisher`; (b) `schema:sponsor`; (c) our own `steward` term defined with the CRA Art. 3(14) meaning | (c) mapped as a sub-property of (a): no standard term carries the CRA meaning, and `publisher` is the closest general one **Shane:** *(c) agreed, and include both documentation and schema-file-comment notes pointing at CRA taxonomy description* |
| 10 | Licence for `stewards.jsonl` and the JSON-LD export | (a) CC0-1.0; (b) Apache-2.0 like the repo; (c) CC-BY-4.0 | (a): facts with no attribution burden, which makes ingestion by ecosyste.ms (CC-BY-SA) and others simplest **Shane:** *(a) agreed, for factual data points we are gathering automatically, CC0-1.0 is best; for any human authored text or code, we should use Apache-2.0 unless there is a reason not to (like sharing with ecosystems is a good reason)* |
| 11 | When to contact ecosyste.ms | (a) now, with this plan; (b) after the pilot export exists | (b): a working `stewards.jsonl` is a concrete ask *(b) agreed* |

> **Shane, IMPORTANT documentation standard:** include links clarifying taxonomy descriptions, directly to standards or other sources, both in our schema files and in our documentation, so that even metadata researchers who want to understand what our data means can cleanly and accurately determine.

> **Shane, IMPORTANT design choice:** we do not want to duplicate ecosyste.ms data; we want to complement it wherever possible. For question 2, (c) is the right answer, because it provides both some rich data tying together our data with ecosystems, and because it provides a super simple export csv that only includes core data. While this design means more automated maintenance (to update both files), it keeps separation of what we actually store more organized.

> **Shane, NEW TASK:** once implementation of patch steps 1 and 2 is complete, plan out a way to optionally store some of the `_data/attestors.json` data in a Github secret or other non-public repository - this would allow some foundation leadership to only share name/email with project maintainers, but would still be able to tie the public part of an attestors data (i.e. role, foundation, date, etc.) solidly to a real person for legal or maintainer purposes.

## What was built (steps 1 and 2)

| Area | As built |
| --- | --- |
| Schema | `_data/crosswalk-schema.json` moved to JSON Schema draft-07; every field has a `$comment` linking the standard it maps to |
| Accounts | `platformId` on the 8 pilot GitHub orgs (e.g. apache 47359), `lastReviewed`, `reviewedBy` |
| Packages | 7 pilot entries, e.g. `pkg:pypi/numpy`, `pkg:maven/org.apache.kafka/kafka-clients`, each with live-checked evidence; `evidence[].about` holds release purls |
| Human attestation | `human-attested` type requiring `creator`, `method`, `confirmedWith` (`name` optional, `email`, `roleName`, `memberOf`); `_data/attestors.json` lists ShaneCurcuru as the first attestor |
| Confidence | listed attestors confirm; `supersedes` overrides an older contradiction; `stale` after 90 days, or 1 year for steward-declared and human-attested |
| Simple CSV | `purl` and `codeRepository` columns added to `projects-asf.csv` and `projects-numfocus.csv`, filled by `fdncrosswalk sync-csv` (kafka, numpy, matplotlib so far) |
| Exports | `api/v1/crosswalk/`: per-foundation JSON-LD, `context.jsonld`, `vocab.jsonld` (defines `fdn:steward` as a sub-property of `schema:publisher` with the CRA Art. 3(14) meaning), `stewards.jsonl`; CC0-1.0 |
| Docs | new site page `/crosswalk` (`_pages/crosswalk.md`) with a vocabulary table and a link for every term |

Two things to check in review: the CSV change touches every row (two empty columns appended), and the CRA Art. 3(14) text on the docs page is a paraphrase, because EUR-Lex was not readable from here.

## Plan: private attestor data (new task)

Recommendation: keep the private details in a **private companion repository**, and put an opaque id plus the public facts in the public crosswalk. A GitHub secret is the wrong store for this.

| Option | How it works | Fit |
| --- | --- | --- |
| (a) Private repo, e.g. `Punderthings/fossfoundation-private` | Holds `attestations.json`: opaque id → name, email, consent date. Maintainers read it with normal repo access; CI reads it with a fine-grained read-only token stored as a secret | Recommended: readable by trusted maintainers, auditable history, easy to correct or delete |
| (b) GitHub Actions secret | Store the JSON as a secret value | Poor: secrets are write-only after saving, so no person can read them back, and they are size-limited; only a workflow can use them |
| (c) Encrypted file in the public repo (sops or age) | Ciphertext in git, key held by maintainers and CI | Workable, but a leaked key exposes all history, and deleting someone's data means rewriting git history |

What the public record keeps, so it still ties to a real person:

- `confirmedWith.identifier`: a random opaque id such as `urn:uuid:…`, never a hash of the email (email hashes are easy to reverse by guessing).
- `roleName`, `memberOf`, `observed`, `method`, and the attestor's login, as today.
- Optionally `confirmedWith.commitment`: SHA-256 of a secret salt plus the email, with the salt kept privately, so the person can later prove it was them without exposing the email now.

Schema change: `confirmedWith` would require `roleName` plus either `email` or `identifier`, so public and private styles both validate. A CI check in the public repo would confirm every `identifier` exists in the private file; pull requests from forks get no secrets, so the check runs only on the main branch.

Questions for Shane:

1. Private repo (a), or do you prefer (c)?
2. Should the private record also keep a consent date and how the person agreed? This helps if a person in the EU asks for their data under the GDPR.

Once you pick, the work splits into three patches, each small enough to review on its own:

1. Schema and pilot data: new account fields, `packages[]`, `human-attested`, `attestors.json`, confidence rules, tests.
2. Exports: `<identifier>.json`, `context.jsonld`, `stewards.jsonl` from the Jekyll build.
3. The monthly refresh Action and review queue.

Pushes to Punderthings/fossfoundation are still refused from here, so each would arrive as a patch in project files unless you grant write access.

## Sources

All checked on 2026-10-28 with `mailto=` a polite email.

- ecosyste.ms OpenAPI specs: [packages](https://packages.ecosyste.ms/docs/api/v1/openapi.yaml), [repos](https://repos.ecosyste.ms/docs/api/v1/openapi.yaml), [sponsors](https://sponsors.ecosyste.ms/docs/api/v1/openapi.yaml), [papers](https://papers.ecosyste.ms/docs/api/v1/openapi.yaml)
- Live records: linked in the review table above, plus the [repos host list](https://repos.ecosyste.ms/api/v1/hosts)
- Vocabularies: [schema.org identifier](https://schema.org/identifier), [sameAs](https://schema.org/sameAs), [lastReviewed](https://schema.org/lastReviewed), [codeRepository](https://schema.org/codeRepository), [measurementTechnique](https://schema.org/measurementTechnique), [validThrough](https://schema.org/validThrough); [CodeMeta 3.0](https://codemeta.github.io/terms/); [DCMI terms](https://www.dublincore.org/specifications/dublin-core/dcmi-terms/); [W3C PROV-O](https://www.w3.org/TR/prov-o/); [purl spec](https://github.com/package-url/purl-spec)
- Earlier work: [Foundation namespaces on forges and registries](2026-10-28-foundation-namespaces-survey.md), [Crosswalk fields and evidence across registries](2026-10-28-crosswalk-fields-evidence.md), patches 0001 and 0002 and `handoffs/HANDOFF-fdn-ecosystems.md` in project files
