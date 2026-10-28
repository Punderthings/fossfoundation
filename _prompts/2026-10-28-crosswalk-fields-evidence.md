# Crosswalk fields and evidence across registries

2026-10-28 · Shane Curcuru, with Claude

> Converted from a Claude Docs plan document on 2026-10-28. Comments from Shane Curcuru are kept inline (marked **SC:** or **Shane:**). Links to the other plan documents point to their copies in this directory; patch files mentioned (`0001`–`0003`) were saved outside the repository while Claude had no push access.

## Prompt

Shane, 2026-10-28, after answering the open questions in [Foundation namespaces on forges and registries](2026-10-28-foundation-namespaces-survey.md):

> Read comments on Open Questions and start research and implementation of the first steps suggested.

This document is the "brief document comparing the specific fields" Shane asked for in his answer to the PyPI open question. Later the same day Shane also asked to re-check browser access to ecosyste.ms and GitHub verified badges; the badge results are reflected in the pilot results below.

One record shape covers every platform: a foundation has **accounts** (an org, namespace or owner on a platform), and each account carries a list of **evidence** items with a source URL and the date observed. Confidence is computed from the evidence, never typed by hand. This keeps the meaning of "this foundation controls this account" the same on GitHub, npm, Maven Central, PyPI, Docker Hub and RubyGems, even though each platform documents and exposes ownership differently.

Live checks on 28 Oct 2026 show why evidence matters more than names: the npm scope `@psf` belongs to an unrelated "Permissionless Software Foundation", and the PyPI org `python` publishes from the GitHub org `psf`. The pilot data and the tool that checks it are in the repo branch described at the end.

## Generic fields

Each foundation gets one file, `_data/crosswalk/<identifier>.json`, kept apart from the foundation record so tools can regenerate it. Its schema is `_data/crosswalk-schema.json`.

| Field | Required | Meaning | Example |
| --- | --- | --- | --- |
| `identifier` | yes | Foundation id, same as the `_foundations/` file | `python` |
| `accounts[].platform` | yes | Host or registry, named as ecosyste.ms names it | `pypi.org` |
| `accounts[].host` | no | Base URL of a self-hosted forge | `https://gitlab.eclipse.org` |
| `accounts[].kind` | yes | `organization`, `namespace` (npm scope, Maven groupId) or `user` | `organization` |
| `accounts[].name` | yes | Login, scope or groupId exactly as the platform spells it | `@psf`, `org.apache` |
| `accounts[].url` | yes | Public page for the account | `https://pypi.org/org/python/` |
| `accounts[].project` | no | Hosted project that owns the account, for fiscal hosts like NumFOCUS | `numpy` |
| `accounts[].evidence[]` | yes, 1+ | Why we believe the link; see next section |  |
| `evidence[].type` | yes | One of nine evidence types | `publish-provenance` |
| `evidence[].source` | yes | URL where anyone can check it again | a PyPI provenance URL |
| `evidence[].observed` | yes | Date last checked | 2026-10-28 |
| `evidence[].detail` | no | One sentence on what the source shows |  |

This replaces the `codeOwners` and `packageNamespaces` fields proposed earlier: one list covers both, and the platform value says which kind it is.

## Evidence types and confidence

Evidence types describe *who asserted the link and how*, so they mean the same thing on every platform. Confidence is the strongest level any evidence reaches, except that one contradiction rejects the account.

| Evidence type | Who asserts it | Examples | Confidence it gives |
| --- | --- | --- | --- |
| `steward-declared` | The foundation, on its own site or in policy | ASF homepage links github.com/apache; Eclipse handbook names gitlab.eclipse.org | confirmed |
| `platform-verified` | The platform, after checking a domain or identity | GitHub Verified badge; Maven Central DNS TXT check; Flathub domain check | confirmed |
| `profile-claim` | The account holder, in its own profile | Docker Hub `company` and `profile_url`; PyPI org display name | probable |
| `program-badge` | The platform, via a program | Docker Hub `badge: open_source` | probable |
| `publish-provenance` | A signed build record | PyPI attestation shows numpy built in github.com/numpy/numpy-release | probable |
| `repository-link` | The publisher, in package metadata | npm `repository` points to github.com/apache/opendal | probable |
| `namespace-convention` | A documented naming rule | Maven `org.apache` maps to apache.org; Eclipse orgs are `eclipse-<project>` | probable |
| `name-match` | Nobody; the names are the same | Docker Hub `numfocus` org with no link to numfocus.org | unconfirmed |
| `contradiction` | Any source showing someone else controls it | npm `@psf` publishes Bitcoin Cash libraries | rejected |

Two rules keep this honest across registries. First, an account only reaches "confirmed" when the foundation or the platform says so; self-description and build records stay "probable" until a person checks them. Second, probes only *suggest* evidence, and a person copies what holds up into the file, which matches CONTRIBUTING's rule that data traces back to the organization.

## How each platform documents and exposes the fields

Only Docker Hub returns an org profile with a website through a public JSON API that worked from here; PyPI and npm expose package-level links, and GitHub's org API exists but was blocked from this sandbox.

| Generic field / evidence | GitHub | npm | Maven Central | PyPI | Docker Hub | RubyGems |
| --- | --- | --- | --- | --- | --- | --- |
| Account record | REST `/orgs/{org}` | `/-/org/{scope}/package` (package list only) | none; groupId only | org web page only, no API | `/v2/orgs/{org}` | `/api/v1/owners/{handle}/gems.json` |
| `profile-claim` fields | `name`, `blog`, `email` | none | none | display name | `full_name`, `company`, `profile_url` | none |
| `platform-verified` | `is_verified` (DNS TXT) | none | DNS TXT at namespace registration, not published | admin approval with email-domain check, domain not published | Verified Publisher (paid) | none; orgs in private beta |
| `program-badge` | none | none | none | none | `badge` (`open_source`) | none |
| `repository-link` | n/a | package `repository` | POM `<scm>` | `project_urls` ("Source") | OCI label `org.opencontainers.image.source` per image | gem `source_code_uri` |
| `publish-provenance` | artifact attestations | Sigstore provenance in `dist.attestations` | PGP `.asc` only (no repo link) | integrity API `publisher` | none (Content Trust retired) | trusted publishing (no public attestation seen yet) |
| `namespace-convention` | n/a | none | reverse-DNS groupId; `io.github.<user>` | none until PEP 752 grants | none | none |
| Where documented | docs.github.com | docs.npmjs.com | central.sonatype.org | docs.pypi.org, PEPs 740 and 752 | docs.docker.com | guides.rubygems.org |

Rows marked "none" are the gaps where we must rely on `steward-declared` evidence from the foundation's own site.

## PyPI in depth

PyPI gives us two strong signals and one weak one: per-file provenance naming the source repository (strong), project URLs it has verified (strong), and org display names (weak, because the org's website is not public).

| PyPI field | Where it is documented | How we read it | Evidence type | Live sample, 28 Oct 2026 |
| --- | --- | --- | --- | --- |
| Organization name and display name | [Org FAQ](https://docs.pypi.org/organization-accounts/org-acc-faq/) | Scrape `https://pypi.org/org/<name>/`; no API | `profile-claim` | `apache` = "The Apache Software Foundation" (asfpy, asfquart); `psf` = "Python Software Foundation" (cachecontrol) |
| Org approval | Org FAQ: admins approve; requester email domain must match the org URL | Not observable; the org URL is not shown | none recorded | n/a |
| Projects owned by an org | Org page | Scrape project links | supports `profile-claim` | `python` owns pyperf, pyperformance, python-docs-theme, turtle-translations, tzdata |
| `project_urls` | [Project metadata](https://docs.pypi.org/project_metadata/) | JSON API `/pypi/<project>/json` | `repository-link` | numpy "source" = github.com/numpy/numpy |
| Verified project URLs | Project metadata docs | Web UI only; not in the JSON API | `platform-verified` (per project, not per org) | not yet sampled |
| Provenance `publisher` | [PEP 740](https://peps.python.org/pep-0740), [attestations docs](https://docs.pypi.org/attestations/) | Simple JSON index `provenance` URL, then `/integrity/<project>/<version>/<file>/provenance` | `publish-provenance` | pyperf 2.10.0 ← `psf/pyperf`, numpy 2.5.4 ← `numpy/numpy-release`, matplotlib 3.11.2 ← `matplotlib/matplotlib-release` |
| Namespace grant | [PEP 752](https://peps.python.org/pep-0752/) (accepted 29 Jun 2026) | Not live yet | `platform-verified` once live | n/a |

**Correction to the first doc:** live provenance records carry only `kind`, `repository`, `workflow` and `environment`. The `repository_owner_id` field appears in PEP 740's example but not in what PyPI serves today, so we key on the repository name and should treat renames with care.

**Coverage is partial.** Only files uploaded through trusted publishing carry provenance: 1,128 of 4,298 numpy files, 6 of 40 pyperf files, and none of jupyterlab's 1,209 or asfquart's 28. So a missing attestation is not evidence against a link.

**How we collect evidence for a PyPI link:**

1. Start from a confirmed forge org for the foundation or project.
2. For each PyPI project linked to it, run `fdncrosswalk probe pypi.org <project>` to read the newest attestation.
3. If the publisher repository is inside a confirmed org, add `publish-provenance` to the PyPI org that owns the project.
4. Read the org page and add `profile-claim` when its display name names the foundation or project.
5. Record PEP 752 grants as `platform-verified` once PyPI starts granting them.

## Link to CRA attestations

The crosswalk answers a question the VSA-lite attestation leaves open: which registry and forge accounts may legitimately carry a steward's releases. An attestation binds released files by digest, but users install from npm, PyPI, Maven Central or Docker Hub, so verifiers need to know which accounts on those platforms belong to the issuing steward.

The ORC WG [template-lite](https://github.com/orcwg/cra-attestations/blob/main/proposals/template-lite.md) (v0.1, derived from BSI TR-03185-2) has 3 authorship items and 19 controls. `asf-cra-attestations` turns it into the VSA-lite JSON schema, with ASF baseline answers in `format/baseline/asf.json`. The fields that overlap with fossfoundation data:

| VSA-lite field (template item) | fossfoundation source | Fit |
| --- | --- | --- |
| `issuer.name`, `issuer.website` (AU.01) | foundation `legalName`, `website` | Direct |
| `issuer.registeredAddress` (AU.01) | foundation `addressCountry`, `addressRegion` only | Partial; no street address |
| `issuer.role` = `steward` (CRA Art. 3(14)) | none yet | Gap: add a foundation field for a publicly stated CRA steward role |
| `contact` (AU.02) | leadership dataset (other thread) | Future |
| `subject.project.url`, `subject.project.purl` (AU.03) | hosted projects plus crosswalk `project` accounts | Direct once projects carry purls |
| `subject.release.vcs.url` (QA.02) | crosswalk forge accounts at `confirmed` | Direct: the repo must sit in a confirmed org |
| `artifact.uri`, `artifact.purl`, `artifact.official` | crosswalk registry accounts | Direct: tells which registry copies come from the steward; registry copies are usually `official: false` convenience binaries |
| `signature.identity` (sigstore workflow) | crosswalk `publish-provenance` evidence (repository + workflow) | Same data, reused |
| `signature.keysUri`, `keyFingerprint` (BR.03) | none | Out of scope |
| `VM.01.contact`, `privateReportingUri` | foundation `securityurl` | Direct for the URL |
| LE.01 licence | foundation `licenses` | Foundation default only |
| BR.03 integrity method | comparison table: provenance support per registry | Context per platform |

Two concrete hooks: the `vsa-collect` collector reads only downloads.apache.org and repo1.maven.org today, and the crosswalk could tell it which PyPI, npm and Docker Hub accounts to check for convenience binaries. In return, published attestations would be strong `steward-declared` evidence for the crosswalk. For the dataset description, I suggest one sentence noting that the crosswalk supports CRA steward attestations, plus a new optional foundation field for a public steward statement URL.

## Pilot results

The five pilot files hold 24 accounts: 8 confirmed, 14 probable, 1 unconfirmed and 1 rejected. Six GitHub orgs are confirmed by GitHub's Verified-domain badge (checked on their public profiles): apache (www.apache.org), eclipse (eclipse.org), python (www.python.org), psf (python.org), openjs-foundation (openjsf.org) and matplotlib (matplotlib.org). No registry account reached "confirmed", because no pilot registry publishes a foundation-level verification we could read.

| Foundation | Confirmed | Probable | Unconfirmed / rejected | Notes |
| --- | --- | --- | --- | --- |
| asf | github.com/apache (Verified) | Maven `org.apache`, Docker Hub `apache` (open source badge), PyPI org `apache`, npm `@apache` (OpenDAL) |  | OpenDAL is missing from `projects-asf.csv` |
| eclipse | github.com/eclipse (Verified), github.com/eclipse-csi, gitlab.eclipse.org/eclipse | Docker Hub `eclipse` (badge), Maven `org.eclipse` |  | eclipse-csi has no Verified badge but is linked from eclipse.org; per-project `eclipse-<name>` orgs not yet listed |
| python | github.com/python and github.com/psf (both Verified) | PyPI orgs `psf` and `python`, Docker Hub `python` | npm `@psf` rejected | The official `python` Docker image is maintained under Docker's `library`, not this org |
| numfocus | github.com/matplotlib (Verified) | PyPI orgs `numpy`, `matplotlib`; github.com/numpy (no badge); Docker Hub `jupyter` | Docker Hub `numfocus` unconfirmed | Accounts belong to projects, as expected for a fiscal host |
| openjsf | github.com/openjs-foundation (Verified) | Docker Hub `nodejs` |  | npm scopes `@openjs` and `@openjs-foundation` exist but list no packages |

RubyGems is in the schema and tool, but none of the five pilots owns gems; Ruby Central is the natural foundation to pilot it next.

**Code:** schema, pilot data and the `fdncrosswalk` tool (validate, report, ecosyste.ms URLs with mailto, and Docker Hub, PyPI and npm probes; 21 offline tests passing) are committed on branch `claude/project-thread-391x9u`. The push to GitHub was refused, so the commit is also saved as a patch in project files.

**Blocked from this environment:** GitHub's org API (badges were read from public profile pages instead), all ecosyste.ms hosts, Maven Central search (rate-limited), and Claude for Chrome, which project threads cannot use while the account requires trusted devices. The site build (`bundle exec jekyll build`) also did not run here because of a Ruby version mismatch.

## Sources

All checked on 2026-10-28. Each pilot account's own sources are in its crosswalk file.

- [ORC WG template-lite](https://github.com/orcwg/cra-attestations/blob/main/proposals/template-lite.md) and [asf-cra-attestations](https://github.com/ShaneCurcuru/asf-cra-attestations) (`format/vsa/schema/vsa-lite.schema.json`, `format/baseline/asf.json`, `format/vsa/collect/README.md`)
- PyPI: [org FAQ](https://docs.pypi.org/organization-accounts/org-acc-faq/), [project metadata](https://docs.pypi.org/project_metadata/), [attestations](https://docs.pypi.org/attestations/), [PEP 740](https://peps.python.org/pep-0740), [PEP 752](https://peps.python.org/pep-0752/), [PEP 755](https://peps.python.org/pep-755/)
- Live API samples: [Docker Hub org apache](https://hub.docker.com/v2/orgs/apache/), [npm org psf](https://registry.npmjs.org/-/org/psf/package), [numpy JSON](https://pypi.org/pypi/numpy/json), [pyperf provenance](https://pypi.org/integrity/pyperf/2.10.0/pyperf-2.10.0.tar.gz/provenance), [PyPI org python](https://pypi.org/org/python/)
- Foundation pages: [apache.org](https://www.apache.org/), [eclipse.org](https://www.eclipse.org/), [Eclipse project handbook](https://www.eclipse.org/projects/handbook/), [PSF](https://www.python.org/psf/), [openjsf.org](https://openjsf.org/)
- [Maven Central namespace registration](https://central.sonatype.org/register/namespace/)
- Earlier survey: [Foundation namespaces on forges and registries](2026-10-28-foundation-namespaces-survey.md)
