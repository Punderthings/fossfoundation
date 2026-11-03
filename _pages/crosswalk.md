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
| `source` | [dcterms:source](http://purl.org/dc/terms/source) | URL where anyone can check the evidence again; for human attestations, the pull request or signed commit that recorded it. |
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
| `human-attested` | A trusted person who confirmed it out of band with someone at the organization | confirmed if the recorder is a listed [attestor](#attestors), otherwise probable |
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

[`_data/attestors.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestors.json) lists the people whose human attestations count as confirmed: each is a [schema:Person](https://schema.org/Person) with a GitHub `login`, `name`, `sameAs` profile links and `dateAdded`. Adding someone is itself a reviewed pull request. This reflects the personal trust between people in foundation leadership: some confirmations of ownership can only be checked out of band by someone the foundation's leaders know.

## People who confirmed links {#people}

Each person behind a `human-attested` item has one record, validated by [`_data/attestations-schema.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestations-schema.json). Crosswalk evidence points to it by `identifier`, an opaque `urn:uuid:` ([RFC 9562](https://www.rfc-editor.org/rfc/rfc9562)) that is random, never derived from the person's details. The same schema covers both places a record can live:

- **Public**, in [`_data/attestations.json`](https://github.com/Punderthings/fossfoundation/blob/main/_data/attestations.json), only when the person agreed to publication (`consent.publish` is true).
- **Private**, in the maintainers' private repository, which only maintainers can read. This is the default.

| Field | Standard term | Meaning |
| --- | --- | --- |
| `identifier` | [schema:identifier](https://schema.org/identifier) | Opaque `urn:uuid:`; all zeros is reserved for test records. |
| `visibility` | | `public` or `private`, as above. |
| `name` | [schema:name](https://schema.org/name) | Optional. |
| `email` | [schema:email](https://schema.org/email) | Preferably at the foundation's own domain. |
| `roleName`, `memberOf` | [schema:roleName](https://schema.org/roleName), [schema:memberOf](https://schema.org/memberOf) | Role at the organization, and its `_foundations` identifier. |
| `recordedBy` | [dcterms:creator](http://purl.org/dc/terms/creator) | GitHub login of the attestor. |
| `dateCreated`, `dateModified` | [schema:dateCreated](https://schema.org/dateCreated), [schema:dateModified](https://schema.org/dateModified) | When the record was made and last changed. |
| `consent` | [GDPR Art. 7](https://gdpr-info.eu/art-7-gdpr/) | `dateGiven`, `method` (the evidence methods above), `evidence` (where to find it again), `purpose` ([Art. 5(1)(b)](https://gdpr-info.eu/art-5-gdpr/)), `legalBasis` (normally [Art. 6(1)(a)](https://gdpr-info.eu/art-6-gdpr/)), `publish`, and `withdrawn`. |
| `retainUntil` | [GDPR Art. 5(1)(e)](https://gdpr-info.eu/art-5-gdpr/) | Date to review whether the record is still needed; one year by default. |
| `usedIn` | | Crosswalk files whose evidence uses this identifier. |

Add a record with `uv run fdncrosswalk add-person` in `assets/python/fdncrosswalk`. It asks the questions above, makes the identifier, saves the record to the public file or to the private repository's `attestations.json`, and prints the `confirmedWith` to put in the evidence.

## Steward {#steward}

`fdn:steward` links a foundation to an account or package it stewards. It is a sub-property of [schema:publisher](https://schema.org/publisher). Where the foundation has said so publicly, it carries the meaning of **open-source software steward** in Article 3(14) of the [EU Cyber Resilience Act (Regulation (EU) 2024/2847)](https://eur-lex.europa.eu/eli/reg/2024/2847/oj). In paraphrase, that is a legal person, other than a manufacturer, that gives sustained support to the development of specific free and open-source software intended for commercial activities and ensures its viability; see Article 3(14) for the exact wording. The crosswalk tells verifiers of CRA attestations which registry accounts may carry a steward's releases.

Other terms: <span id="wikidataId"></span>`fdn:wikidataId` is the foundation's [Wikidata](https://www.wikidata.org/) item.

## Exports

Generated by `fdncrosswalk export` and published under [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/), since they are factual data points gathered largely automatically. Code and human-written text in this repository stay under Apache-2.0.

| File | Contents |
| --- | --- |
| `/api/v2/crosswalk/<foundation>.json` | One foundation's crosswalk as JSON-LD, with computed `confidence`, `stale` and a `sameAs` link to the ecosyste.ms page for each account. |
| [`/api/v2/crosswalk/context.jsonld`](/api/v2/crosswalk/context.jsonld) | JSON-LD context mapping every key to the terms above. |
| [`/api/v2/crosswalk/vocab.jsonld`](/api/v2/crosswalk/vocab.jsonld) | RDFS definitions of the `fdn:` terms. |
| [`/api/v2/crosswalk/stewards.jsonl`](/api/v2/crosswalk/stewards.jsonl) | One line per confirmed or probable link, with keys named as ecosyste.ms names them (`host`, `login`, `uuid`, `registry`, `namespace`, `purl`) plus `steward`, `stewardName`, `stewardWikidata`, `project`, `confidence` and `stale`, for bulk joins. |
