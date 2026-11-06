---
title: Platform Crosswalk
excerpt: Which code host and package registry accounts each foundation controls, and the evidence for each link.
layout: default
permalink: /crosswalk
parent: Data Models
nav_order: 20
---

The crosswalk records which accounts and packages on code hosts and package registries belong to a foundation or one of its hosted projects, and why we believe each link. It is built to complement [ecosyste.ms](https://ecosyste.ms/): we store identifiers and our own evidence, and link to ecosyste.ms for metrics such as stars, downloads and paper mentions rather than copying them.

- Data: [`_data/crosswalk/<foundation>.json`](https://github.com/Punderthings/fossfoundation/tree/main/_data/crosswalk), validated by [`_data/crosswalk-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/crosswalk-schema.json).
- Simple export: the `purl` and `codeRepository` columns of `_data/projects-<foundation>.csv` hold each hosted project's main package and repository, copied from the crosswalk.
- Evidence and attestations: every link carries [evidence](#evidence); confirmations made in person are recorded by trusted [attestors](#attestors), with [records of the people who confirmed them](#people), following the [attestor workflow](#attestor-workflow).
- Linked-data exports: [`/api/v2/crosswalk/`](#exports).
- File overview: [Crosswalk Data Files](/crosswalk-files).
- Tool: [`assets/python/fdncrosswalk`](https://github.com/Punderthings/fossfoundation/tree/main/assets/python/fdncrosswalk).

## Vocabularies used

Every field maps to an existing, widely used term where one exists. The [JSON-LD context](/api/v2/crosswalk/context.jsonld) states these mappings in machine-readable form.

| Vocabulary | Used for | Reference |
| --- | --- | --- |
| Schema.org | identifiers, URLs, people, roles, review dates | [schema.org](https://schema.org/) |
| Dublin Core Terms | evidence type, source, description, creator | [DCMI Metadata Terms](https://www.dublincore.org/specifications/dublin-core/dcmi-terms/) |
| W3C PROV-O | evidence as provenance of a claim, and when it was observed | [PROV-O](https://www.w3.org/TR/prov-o/) |
| Package URL (purl), ECMA-427 | package and repository identifiers | [purl specification](https://github.com/package-url/purl-spec), [ECMA-427](https://ecma-international.org/publications-and-standards/standards/ecma-427/) |
| CodeMeta | `codeRepository` and purl-as-identifier, as ecosyste.ms serves them | [CodeMeta terms](https://codemeta.github.io/terms/) |
| ecosyste.ms names | platform, host and registry names | [registries](https://packages.ecosyste.ms/api/v1/registries), [hosts](https://repos.ecosyste.ms/api/v1/hosts) |
| fossfoundation terms (`fdn:`) | terms no standard covers; defined below and in [vocab.jsonld](/api/v2/crosswalk/vocab.jsonld) | this page |

## Accounts {#account}

An account is an org, namespace or owner on one platform.

| Field | Standard term | Meaning |
| --- | --- | --- |
| <span id="platform"></span>`platform` | `fdn:platform` | Code host or registry, named as ecosyste.ms names it, e.g. `github.com`, `pypi.org`. |
| <span id="host"></span>`host` | `fdn:host` | Base URL of a self-hosted forge such as `https://gitlab.eclipse.org`. |
| <span id="accountKind"></span>`kind` | `fdn:accountKind` | `organization`, `namespace` (npm scope, Maven groupId) or `user`. |
| `name` | [schema:name](https://schema.org/name) | Login, scope or groupId as the platform spells it; joins to the ecosyste.ms owner `login` or namespace `name`. |
| `platformId` | [schema:identifier](https://schema.org/identifier) | The platform's stable numeric id (GitHub org id, also the ecosyste.ms owner `uuid`), which survives renames. See [OpenSSF guidance on rename attacks](https://repos.openssf.org/trusted-publishers-for-all-package-repositories). |
| `url` | [schema:url](https://schema.org/url) | Public page for the account. |
| <span id="project"></span>`project` | `fdn:project` | Hosted project that owns the account, for fiscal hosts. |
| `lastReviewed`, `reviewedBy` | [schema:lastReviewed](https://schema.org/lastReviewed), [schema:reviewedBy](https://schema.org/reviewedBy) | When and by whom a person last reviewed the whole account. |
| `evidence` | [prov:wasDerivedFrom](https://www.w3.org/TR/prov-o/#wasDerivedFrom) | One or more evidence items. |

## Packages {#package}

A package is a registry package or a source repository, identified by a purl without a version.

| Field | Standard term | Meaning |
| --- | --- | --- |
| `purl` | [schema:identifier](https://schema.org/identifier), value a [purl](https://github.com/package-url/purl-spec) | e.g. `pkg:pypi/numpy`, `pkg:github/apache/kafka`; joins to ecosyste.ms packages, repos and papers. |
| `codeRepository` | [schema:codeRepository](https://schema.org/codeRepository) | Source repository URL. |
| <span id="publishedUnder"></span>`account` | `fdn:publishedUnder` | The account it is published under, as `<platform>/<name>`. |
| `project` | `fdn:project` | Hosted project it belongs to. The first package listed for a project is copied to the project CSV. |
| `lastReviewed`, `reviewedBy`, `evidence` | as for accounts | |

## Evidence

| Field | Standard term | Meaning |
| --- | --- | --- |
| `type` | [dcterms:type](http://purl.org/dc/terms/type) | One of the evidence types below. |
| `source` | [dcterms:source](http://purl.org/dc/terms/source) | URL where anyone can check the evidence again; for human attestations, the pull request or signed commit that recorded it, or `pending` until that pull request exists (exports leave a pending source out). |
| `observed` | [prov:generatedAtTime](https://www.w3.org/TR/prov-o/#generatedAtTime) | Date last checked, or the date a human attestation was done. |
| `detail` | [dcterms:description](http://purl.org/dc/terms/description) | One sentence on what the source shows. |
| `creator` | [dcterms:creator](http://purl.org/dc/terms/creator) | Who recorded it: a GitHub login, or `fdncrosswalk/<version>`. |
| `about` | [schema:about](https://schema.org/about) | The release the evidence is about, as a versioned purl such as `pkg:pypi/pyperf@2.10.0`. |
| `validThrough` | [schema:validThrough](https://schema.org/validThrough) | When it should be checked again (see freshness below). |
| `method` | [schema:measurementTechnique](https://schema.org/measurementTechnique) | Human attestations only: `in-person`, `video-call`, `email-official-domain`, `signed-message` or `foundation-ticket`. |
| <span id="confirmedWith"></span>`confirmedWith` | `fdn:confirmedWith`, a [schema:Person](https://schema.org/Person) | Human attestations only: the person at the organization who confirmed it. Required `roleName` ([schema:roleName](https://schema.org/roleName)), plus `identifier` ([schema:identifier](https://schema.org/identifier)) pointing to their [person record](#people); optional `memberOf` ([schema:memberOf](https://schema.org/memberOf), defaults to the foundation). An inline `name` or `email` is allowed only with the person's agreement, since this repository is public; prefer `identifier`. |
| <span id="supersedes"></span>`supersedes` | `fdn:supersedes` | Human attestations only: overrides an earlier contradiction; explain why in `detail`. |

### Evidence types

| Type | Who asserts it | Gives |
| --- | --- | --- |
| `steward-declared` | The foundation, on its own site or in policy | confirmed |
| `platform-verified` | The platform, after checking a domain or identity, e.g. the [GitHub Verified badge](https://docs.github.com/en/organizations/managing-organization-settings/verifying-or-approving-a-domain-for-your-organization) | confirmed |
| `human-attested` | A trusted person who confirmed it out of band with someone at the organization; a volunteer observation, not a legal attestation (see [legal status](#legal-status)) | confirmed if the recorder is a listed [attestor](#attestors), otherwise probable |
| `profile-claim` | The account holder, in its own profile | probable |
| `program-badge` | A platform program, e.g. Docker-Sponsored Open Source | probable |
| `publish-provenance` | A signed build record, e.g. [PyPI attestations (PEP 740)](https://peps.python.org/pep-0740/) or [npm provenance](https://docs.npmjs.com/generating-provenance-statements) | probable |
| `repository-link` | The publisher, in package metadata | probable |
| `namespace-convention` | A documented naming rule, e.g. [Maven Central namespaces](https://central.sonatype.org/register/namespace/) | probable |
| `name-match` | Nobody; the names are the same | unconfirmed |
| `contradiction` | Any source showing someone else controls it | rejected |

## Confidence {#confidence}

`fdn:confidence` is computed, never stored by hand, by `fdncrosswalk`:

1. Any `contradiction` gives **rejected**, unless a listed attestor's later `human-attested` item sets `supersedes`.
2. Otherwise the strongest evidence wins: **confirmed**, then **probable**, then **unconfirmed**.
3. <span id="stale"></span>**Stale** (`fdn:stale`): true when every item supporting that level is past its freshness date. Evidence is fresh until `validThrough` if given, otherwise for one year after `observed` for `steward-declared` and `human-attested`, and 90 days for everything else. Contradictions never expire.

## Attestors {#attestors}

Some links can't be proved from public pages. A Docker Hub organization, an npm scope or a PyPI organization may carry no domain check and no link back to the foundation's site, yet the foundation's own infrastructure team knows it is theirs. For those, the crosswalk accepts `human-attested` evidence: a person confirmed the link directly, out of band, with someone at the organization.

**Attestors** are the small group of people whose human attestations the project trusts enough to count as **confirmed**. They are usually people in or close to FOSS foundation leadership, such as officers, directors, or infrastructure staff, who personally know the leaders of other foundations. An attestor does not have to work for the foundation whose link they confirm; what counts is that they confirmed it with someone there. This mirrors how trust already works between foundation leaders: some confirmations of ownership can only be made by someone the foundation's leaders know.

For a researcher, the key facts are:

- Every `human-attested` evidence item names its attestor in `creator`, as a GitHub login. Join it to [`_data/attestors.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestors.json) to see who they are.
- An attestation by a listed attestor gives **confirmed**. The same evidence recorded by anyone else counts only as **probable** (see [confidence](#confidence)).
- Attestors are always public. The person they confirmed with may not be; see [people who confirmed links](#people).
- Adding someone to the list is itself a reviewed pull request, merged by a maintainer, so the list's git history shows when and by whom each attestor was added.

Each attestor is a [schema:Person](https://schema.org/Person), validated by [`_data/attestors-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestors-schema.json):

| Field | Standard term | Meaning |
| --- | --- | --- |
| `login` | [schema:identifier](https://schema.org/identifier) | GitHub login; matches `creator` on their evidence. |
| `name` | [schema:name](https://schema.org/name) | The attestor's name. |
| `sameAs` | [schema:sameAs](https://schema.org/sameAs) | Profile URLs that identify the person, such as GitHub, ORCID or Wikidata. |
| `dateAdded` | [dcterms:dateAccepted](http://purl.org/dc/terms/dateAccepted) | When the maintainers accepted them as an attestor. |
| `memberOf` | [schema:memberOf](https://schema.org/memberOf), each item a [schema:OrganizationRole](https://schema.org/OrganizationRole) | Optional. A list of the organizations the attestor is associated with, each a pair of `memberOf` (a `_foundations` or `_entities` identifier, or the website URL of an organization not listed here) and an optional `roleName` ([schema:roleName](https://schema.org/roleName)). For example, an officer at one foundation and a director at another, or an attestor for several foundations. Left out for attestors not associated with any organization. |
| `keyFingerprint` | | Optional fingerprint of the OpenPGP or SSH key they sign commits with. |

For example, an attestor who is an officer at one foundation and a director at another:

```json
{
  "login": "your-github-login",
  "name": "Your Name",
  "dateAdded": "2026-11-05",
  "memberOf": [
    { "memberOf": "example", "roleName": "Treasurer" },
    { "memberOf": "https://example.org/", "roleName": "Director" }
  ]
}
```

### Legal status of attestations {#legal-status}

Attestations in our data and schemas are provided by volunteers. They may represent informed observations by people who know the organizations involved, but they have not been legally reviewed to qualify as "attestations" under the [EU Cyber Resilience Act](#steward) or any other legislation. We may seek legal advice on how our tools could directly support CRA compliance, but we do not currently claim that the crosswalk, its evidence, or our tools are certified to do so. Treat a `human-attested` link as a documented, good-faith confirmation, and check the organization's own statements wherever a legal decision depends on it.

## People who confirmed links {#people}

Behind every `human-attested` item there are two people: the attestor who recorded it, and the person at the organization who confirmed it to them. That second person is typically an officer, director, or staff member responsible for the accounts in question, for example a foundation's head of infrastructure or its executive director.

What a researcher can always see in the public evidence is that person's **role** (`roleName`), their **organization** (`memberOf`, a `_foundations` identifier), **how** they confirmed it (`method`), and **when** (`observed`). Their name and email are kept in a separate **person record**, which is private unless they agreed to publication. This keeps personal information out of a public repository, as the [GDPR](https://gdpr-info.eu/) and our own privacy rules expect, while still letting maintainers tie every attestation to a real, reachable person if it is ever questioned.

Each person has one record, validated by [`_data/attestations-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestations-schema.json). Crosswalk evidence points to it by `identifier`, an opaque `urn:uuid:` ([RFC 9562](https://www.rfc-editor.org/rfc/rfc9562)) that is random, never derived from the person's details, so the public data can't be used to look a person up. The same identifier is used for every link that person confirmed, so you can count distinct people without knowing who they are. The same schema covers both places a record can live:

- **Public**, in [`_data/attestations.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestations.json), only when the person agreed to publication (`consent.publish` is true). These records are CC0-1.0.
- **Private**, in the maintainers' private repository, which only maintainers can read. This is the default. If you need a private record checked for research or legal reasons, ask the maintainers; personal details are never shared without the person's consent.

| Field | Standard term | Meaning |
| --- | --- | --- |
| `identifier` | [schema:identifier](https://schema.org/identifier) | Opaque `urn:uuid:`; all zeros is reserved for test records. |
| `visibility` | | `public` or `private`, as above. |
| `name` | [schema:name](https://schema.org/name) | Optional. |
| `email` | [schema:email](https://schema.org/email) | Preferably at the foundation's own domain. |
| `roleName`, `memberOf` | [schema:roleName](https://schema.org/roleName), [schema:memberOf](https://schema.org/memberOf) | Role at the organization, and its `_foundations` identifier. |
| `recordedBy` | [dcterms:creator](http://purl.org/dc/terms/creator) | GitHub login of the attestor. |
| `dateCreated`, `dateModified` | [schema:dateCreated](https://schema.org/dateCreated), [schema:dateModified](https://schema.org/dateModified) | When the record was made and last changed. |
| `consent` | [GDPR Art. 7](https://gdpr-info.eu/art-7-gdpr/) | `dateGiven`, `method` (the evidence methods above, or `self` when attestors record their own details), `evidence` (where to find it again), `purpose` ([Art. 5(1)(b)](https://gdpr-info.eu/art-5-gdpr/)), `legalBasis` (normally [Art. 6(1)(a)](https://gdpr-info.eu/art-6-gdpr/)), `publish`, and `withdrawn`. |
| `retainUntil` | [GDPR Art. 5(1)(e)](https://gdpr-info.eu/art-5-gdpr/) | Date to review whether the record is still needed; one year by default. |
| `usedIn` | | Crosswalk files whose evidence uses this identifier. |

Add a record with `uv run fdncrosswalk add-person` in `assets/python/fdncrosswalk`. It asks the questions above, makes the identifier, saves the record to the public file or to the private repository's `attestations.json`, and prints the `confirmedWith` to put in the evidence.

## Attestor workflow {#attestor-workflow}

This section walks through the whole process, from becoming an attestor to keeping an attestation current.

### Why become an attestor

- **Your foundation's accounts get confirmed** even where no public proof exists. Without an attestation, an account with only a profile claim or a naming convention stays "probable".
- **It protects users of your software.** The crosswalk helps package users, security tools, and people checking [EU Cyber Resilience Act](#steward) attestations see which accounts may legitimately carry a foundation's releases, and it flags look-alike accounts as rejected. Your confirmations are volunteer observations, not legal attestations; see [legal status](#legal-status).
- **It helps peers.** Leaders at smaller foundations often have no time to publish proof for every account; an attestor they already know can confirm it in one conversation.
- **It improves research.** Confirmed links let researchers measure a foundation's software without guessing which accounts are really its own.

Being an attestor is a small, occasional task: a few confirmations a year, each renewed yearly.

### How maintainers check an attestor

1. The candidate opens an issue or pull request that adds their entry to `_data/attestors.json`: GitHub login, name, `sameAs` profile links, and, if they sign commits, their key fingerprint. If they are associated with any organizations, they list each one in `memberOf`, with their `roleName` there.
2. A maintainer checks that each role is real, preferably on the organization's own leadership or team page, and confirms it with the candidate directly, using one of the evidence methods: in person, a video call, email from the organization's official domain, a signed message, or a ticket in the organization's own tracker.
3. The maintainer checks that the GitHub login belongs to that person, for example through the profile links or signed commits.
4. The maintainer merges the pull request, which records `dateAdded`. Attestors are added only by maintainers.

`memberOf` is optional, and so is each `roleName` in it, because some attestors are not associated with a foundation listed here; they may work with an entity, another project, or several organizations, with a different role at each. `fdncrosswalk validate` checks that each `memberOf` names a `_foundations` or `_entities` record, or is a website URL.

### How an attestor adds evidence

Start with a clone of this repository. Only maintainers of this project add data to the private repository, because they are central to the trust model for that data; if you are not a maintainer, send the person's details to a maintainer by whatever channel you both trust, and they create the private record and give you its identifier.

1. **Confirm out of band.** Ask your contact at the organization to confirm that the account or package is theirs, using one of the methods above. Ask, too, whether they agree to their email (and name, if they give it) being kept privately, or published. If you are yourself the officer responsible for the account, you can confirm it with yourself: your person record then uses the consent method `self`.
2. **Run the guided tool.** From `assets/python/fdncrosswalk`, run `uv run fdncrosswalk attest <foundation> --creator <your-login>`. It lists the foundation's accounts and packages to pick from, then asks how and when the link was confirmed, the identifier of the person's record, and one sentence on what they confirmed. Leave the identifier empty to create the person record on the spot, as `uv run fdncrosswalk add-person` does; choose a public record only if the person agreed to publication.
3. **Check what it wrote.** The tool shows the evidence item before saving it, then validates the file and regenerates the [exports](#exports). The item looks like this:

   ```json
   {
     "type": "human-attested",
     "source": "pending",
     "observed": "2026-11-03",
     "detail": "The foundation's director of infrastructure confirmed on a video call that it controls this organization.",
     "creator": "your-github-login",
     "method": "video-call",
     "confirmedWith": {
       "identifier": "urn:uuid:00000000-0000-0000-0000-000000000000",
       "roleName": "Director of Infrastructure",
       "memberOf": "example"
     }
   }
   ```

   This example uses the all-zeros test identifier and placeholder values. If the link has `contradiction` evidence, the tool asks whether your attestation overrides it, and adds `"supersedes": true`; explain why in `detail`.
4. **Open the pull request.** Commit the crosswalk file and the regenerated exports together. `source` starts as the placeholder `pending`; once the pull request exists, replace it with the pull request's URL, or leave that to the maintainer who merges it. `uv run fdncrosswalk report` lists any evidence whose source is still pending. A maintainer reviews and merges the pull request. A new private person record goes in its own pull request in the private repository.

### Keeping attestations current

- **Renew yearly.** A human attestation is fresh for one year after `observed`, unless `validThrough` says otherwise; then the link is marked [stale](#stale). `uv run fdncrosswalk attest --renew --creator <your-login>` lists your attestations that are stale or go stale within 60 days. For each one you confirmed again, it updates `observed` and `method` and sets `source` back to `pending` for the new pull request, keeping the same person identifier. `uv run fdncrosswalk report` lists the attestations due for every attestor.
- **Changes at the organization.** If your contact leaves their role, or the account changes hands, update or remove the evidence.
- **Consent withdrawn.** Delete the person record, and remove or replace the evidence that uses its identifier. A maintainer decides whether git history also needs rewriting to complete an erasure request.

The plan and decisions behind these tools, and ideas for GitHub automation later, are in [`_prompts/2026-11-03-attestor-evidence-tooling.md`](https://github.com/Punderthings/fossfoundation/blob/main/_prompts/2026-11-03-attestor-evidence-tooling.md).

## Steward {#steward}

`fdn:steward` links a foundation to an account or package it stewards. It is a sub-property of [schema:publisher](https://schema.org/publisher). Where the foundation has said so publicly, it carries the meaning of **open-source software steward** in Article 3(14) of the [EU Cyber Resilience Act (Regulation (EU) 2024/2847)](https://eur-lex.europa.eu/eli/reg/2024/2847/oj). In paraphrase, that is a legal person, other than a manufacturer, that gives sustained support to the development of specific free and open-source software intended for commercial activities and ensures its viability; see Article 3(14) for the exact wording. The crosswalk can help people checking CRA attestations see which registry accounts may carry a steward's releases. It is volunteer-maintained information, not a certified compliance tool; see [legal status](#legal-status).

Other terms: <span id="wikidataId"></span>`fdn:wikidataId` is the foundation's [Wikidata](https://www.wikidata.org/) item.

## Exports

Generated by `fdncrosswalk export` and published under [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/), since they are factual data points gathered largely automatically. Code and human-written text in this repository stay under Apache-2.0.

| File | Contents |
| --- | --- |
| `/api/v2/crosswalk/<foundation>.json` | One foundation's crosswalk as JSON-LD, with computed `confidence`, `stale` and a `sameAs` link to the ecosyste.ms page for each account. |
| [`/api/v2/crosswalk/context.jsonld`](/api/v2/crosswalk/context.jsonld) | JSON-LD context mapping every key to the terms above. |
| [`/api/v2/crosswalk/vocab.jsonld`](/api/v2/crosswalk/vocab.jsonld) | RDFS definitions of the `fdn:` terms. |
| [`/api/v2/crosswalk/stewards.jsonl`](/api/v2/crosswalk/stewards.jsonl) | One line per confirmed or probable link, with keys named as ecosyste.ms names them (`host`, `login`, `uuid`, `registry`, `namespace`, `purl`) plus `steward`, `stewardName`, `stewardWikidata`, `project`, `confidence` and `stale`, for bulk joins. |
