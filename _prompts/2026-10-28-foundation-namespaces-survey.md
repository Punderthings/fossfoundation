# Foundation namespaces on forges and registries

2026-10-28 · Shane Curcuru, with Claude

> Converted from a Claude Docs plan document on 2026-10-28. Comments from Shane Curcuru are kept inline (marked **SC:** or **Shane:**). Links to the other plan documents point to their copies in this directory; patch files mentioned (`0001`–`0003`) were saved outside the repository while Claude had no push access.

## Prompt

Shane, 2026-10-28:

> Review the HANDOFF-fdn-ecosystems.md so we can plan to build specific integrations with the ecosyste.ms datasets.
>
> * Start researching ways that FOSS Foundations manage organizational control of their output software products in different common source code hosting platforms, and also in common software project forges.
> * For hosting platforms like: GitHub, Gitea, CodeBerg, and GitLab, research and describe how they allow legal corporations (like the ASF) to claim a namespace, and how they expose that data.
> * For software package registries like: npm, Maven Central, crates.io, NuGet, RubyGems, Go Packages, and Hex; and for system package managers like: apt, yum, and homebrew; and for container registries like: Docker hub, Flat Hub, and Snap Store; research and describe how the registries ensure that packages added to a corporation's namespace are secure and if there are ways to tie package registry organizational records with hosting platforms.
> * Briefly research and report on any standards that you encounter, for example like SPDX to mark licenses or SBOM to store metadata for a specific release on a package registry.

Follow-up answers from Shane in the project chat: PyPI is in scope as one of the most important registries (added to this survey). Answers to the open questions are inline at the end of this document.

## Summary

No forge or registry records "this legal entity stewards this namespace" in a form we can query publicly. The best evidence chain runs through domain names: foundations prove control of a domain (DNS TXT or a `.well-known` file), and several platforms then tie an org or namespace to that domain. fossfoundation already stores each foundation's `website`, so a curated crosswalk of foundation → forge orgs → registry namespaces is both feasible and something ecosyste.ms does not have.

- **Forges:** GitHub is the only one with a public org verification signal (`is_verified`, backed by DNS TXT). GitLab verifies domains only for paid top-level groups and does not show it publicly. Gitea, Forgejo and Codeberg have no org verification.
- **Registries with real org namespaces:** npm scopes, Maven Central groupIds (DNS-verified), NuGet reserved prefixes, PyPI Organizations (with prefix namespaces accepted in PEP 752), Flathub app IDs (domain-verified), Docker Hub orgs. Go uses domains directly in module paths. crates.io, RubyGems and Hex have flat names, so ownership is per package.
- **Publishing security has converged on OIDC trusted publishing** (npm, PyPI, crates.io, RubyGems, NuGet, and Hex in beta since Oct 2026), plus Sigstore provenance. These bind a package release to a specific forge owner and repository, which is the strongest machine-readable registry → forge link today.
- **Distro and app stores** (apt, dnf, Homebrew core, Snap) sign the archive, not the upstream org. Links back to upstream live in metadata files (Debian DEP-12, AppStream, OCI labels).
- **Recommended build path:** add `codeOwners` and `packageNamespaces` lists to foundation records, seed them by hand for 5 pilot foundations, and use ecosyste.ms repos and packages lookups to expand and measure coverage. Details are in the integration plan below.

Note: ecosyste.ms APIs are still blocked from this cloud environment, so no live samples were taken. Facts below are from platform docs fetched today, except where marked "from prior knowledge".

## At a glance

Rows are grouped by type. "Forge link" means a machine-readable tie from the registry record back to a forge org or repo.

| Platform | Org namespace | How an org proves control | Publish security | Forge link | Public API for ownership |
| --- | --- | --- | --- | --- | --- |
| GitHub | Organization login | DNS TXT domain verification, "Verified" badge | 2FA, org policies, artifact attestations | (is the forge) | REST `/orgs/{org}` with `is_verified`, `blog`; GraphQL `domains` (owner-only in practice) |
| GitLab.com | Top-level group path | DNS TXT via Pages, Premium/Ultimate only; not shown publicly | 2FA, protected branches | (is the forge) | `/groups/:id`; no public verification field |
| Gitea / Forgejo | Organization | None | 2FA optional | (is the forge) | `/api/v1/orgs/{org}` with `website`, `email` |
| Codeberg | Organization (Forgejo) | None; Codeberg e.V. terms only | 2FA optional | (is the forge) | Forgejo API |
| npm | `@scope` = npm org | First come; no domain check | 2FA default, trusted publishing (OIDC), Sigstore provenance | Provenance names source repo and workflow | Registry JSON: `maintainers`, `repository`, attestations |
| PyPI | Organization account; name-prefix namespaces accepted (PEP 752, Jun 2026), not yet live | Admin-approved org; email domain must match org URL; free for community projects | 2FA required, trusted publishing (GitHub, GitLab, Google Cloud, ActiveState), PEP 740 attestations | Attestation publisher names repo owner and workflow; verified project URLs | JSON API with project\_urls and per-file provenance URL; org project list on web page only |
| Maven Central | groupId (reverse DNS) | DNS TXT, or forge account for `io.github.*` etc. | PGP signatures required; Central Portal tokens | `io.<forge>.<user>` namespaces; POM `<scm>` | Search API; namespace owners not public |
| crates.io | None (flat names) | n/a; owners are GitHub users or GitHub teams | Trusted publishing (GitHub, GitLab.com), "trusted publishing only" mode | Team owners are `github:org:team` | `/api/v1/crates/{name}/owners` |
| NuGet | Reserved ID prefix (e.g. `Microsoft.*`) | Email request reviewed by nuget.org | Trusted publishing (GitHub, GitLab), author and repo signing | Trusted publishing policy names repo owner | No public reservation API; `verified` flag in search |
| RubyGems | None; Organizations in private beta (Feb 2026) | n/a | MFA, trusted publishing | Trusted publisher config | `/api/v1/gems/{name}/owners.json` |
| Go | Module path = domain or forge path | Control of the domain or repo | Checksum DB (sum.golang.org) transparency log | Module path is the repo or a `go-import` redirect | proxy.golang.org, pkg.go.dev |
| Hex | Organizations (private packages); public names flat | n/a | Trusted publishing beta (Hex 2.6.0, Oct 2026), signed registry | Package `links` metadata | `/api/packages/{name}` with `owners` |
| apt (Debian/Ubuntu) | None; vendor repos are separate archives | Distro developer keyring; vendors use their own key | Signed `InRelease` files | DEP-12 `debian/upstream/metadata` `Repository` | UDD, sources.debian.org |
| yum/dnf (Fedora/EPEL) | None; COPR and vendor repos separate | Fedora Account System packagers | GPG-signed RPMs and repo metadata | Spec `URL:` field only | Fedora PDC/src APIs |
| Homebrew | Tap = forge repo `org/homebrew-x` | Control of the GitHub repo | Bottle build provenance (Sigstore / GitHub attestations) | Tap name is a GitHub org | formulae.brew.sh JSON |
| Docker Hub | Organization | Paid Verified Publisher, or Docker-Sponsored Open Source program | Content Trust retired 2025; Sigstore or Notation recommended | OCI label `org.opencontainers.image.source` | Hub API `/v2/namespaces/{org}/repositories` |
| Flathub | App ID (reverse DNS) | `.well-known` file or DNS TXT on the domain; forge login for `io.github.*`, `io.gitlab.*` | Builds on Flathub infra, signed repo | AppStream `vcs-browser` URL, forge app IDs | flathub.org API with verification status |
| Snap Store | Publisher account | Manual "Verified Account" for companies and foundations | Store-signed assertions | `source-code` field in snapcraft.yaml | Store API (needs device headers) |

## Code hosting platforms

Only GitHub gives a public, machine-readable signal that a legal entity controls an org, and even there it proves a domain, not a legal identity.

**GitHub.** Anyone can create an organization; the login is first come, first served. An org owner can verify a domain by adding a DNS TXT record, which shows a "Verified" badge and requires the profile website and email to match a verified domain ([GitHub docs](https://docs.github.com/en/organizations/managing-organization-settings/verifying-or-approving-a-domain-for-your-organization)). The REST org record exposes `is_verified`, `blog` (website), `email`, `name` and `description`. GraphQL has `isVerified`, `websiteUrl` and a `domains` connection ([GraphQL reference](https://docs.github.com/en/graphql/reference/orgs)); in practice `domains` is only readable by org owners, so we must test it before relying on it. Enterprise accounts can group several orgs (e.g. one foundation's many orgs), but enterprise membership is not public. Legal identity, if any, appears only as free text.

**GitLab.com.** Orgs are top-level groups with subgroups. A group Owner can verify a domain through a GitLab Pages project and a DNS TXT record, but only on Premium or Ultimate plans, and its purpose is claiming "enterprise users" ([GitLab docs](https://docs.gitlab.com/user/enterprise_user)). The docs do not describe any public display or API field for it. Many foundations self-host GitLab instead (GNOME, KDE, freedesktop.org, Eclipse at gitlab.eclipse.org), so the instance hostname itself is the strongest ownership signal.

**Gitea and Forgejo.** Organizations have `full_name`, `website`, `email`, `location` and `description` via `/api/v1/orgs/{org}`. There is no verification feature (from prior knowledge; no doc found that contradicts it). As with GitLab, self-hosted instances owned by a foundation carry the signal by hostname.

**Codeberg.** Runs Forgejo and is operated by Codeberg e.V., a German non-profit. Orgs work as in Forgejo with no verification. Flathub currently lists only GitHub, GitLab, GNOME and KDE as forge verification providers, so Codeberg-hosted apps must verify by domain.

**What this means for us:** for each foundation we can record a list of `{host, login}` pairs and mark which ones GitHub verifies. For self-hosted forges, the host itself is the record. ecosyste.ms repos already indexes about 1,900 hosts including self-hosted GitLab and Forgejo instances, keyed the same way.

## Language package registries

Maven Central checks a domain before granting a namespace and PyPI checks one before approving an organization; the rest secure the publishing step rather than the namespace claim.

**npm.** An npm organization owns one `@scope`, claimed first come, first served, with no domain proof. Security comes from the account and publish path: classic tokens were revoked on 9 Dec 2025, `npm login` now gives 2-hour sessions, new packages default to 2FA, and write tokens last at most 90 days ([GitHub changelog](https://github.blog/changelog/2025-12-09-npm-classic-tokens-revoked-session-based-auth-and-cli-token-management-now-available/)). Trusted publishing via OIDC has been GA since July 2025 ([changelog](https://github.blog/changelog/2025-07-31-npm-trusted-publishing-with-oidc-is-generally-available/)) and attaches Sigstore provenance naming the source repo and workflow. That provenance is the best npm → forge link. Foundations such as OpenJS publish under many scopes and unscoped names, so a scope list will never be complete.

**Maven Central.** A groupId namespace is verified by a DNS TXT record on the matching domain (`org.apache` → apache.org), or by a temporary public repo for `io.github.<user>`, `io.gitlab.<user>`, `io.gitee.<user>` and `io.bitbucket.<user>` ([Sonatype docs](https://central.sonatype.org/register/namespace/)). Releases must be PGP-signed. This makes Maven groupIds the cleanest domain-backed org namespace of any registry. The ASF and Eclipse publish through their own Nexus instances that sync to Central (from prior knowledge).

**crates.io.** Names are flat; an open-namespaces RFC is accepted but not shipped. Owners are GitHub users or GitHub teams (`github:<org>:<team>`), and login is GitHub-only, so a team owner is a direct crate → GitHub org link. Trusted publishing works from GitHub Actions and GitLab.com, with an optional "trusted publishing only" mode ([Jan 2026 update](https://blog.rust-lang.org/2026/01/21/crates-io-development-update)).

**NuGet.** Organizations exist as account types, and an owner can request an ID prefix reservation (e.g. `Microsoft.*`) by email. nuget.org reviews it against criteria such as whether the prefix clearly identifies the owner; reserved packages show a verified checkmark ([Microsoft docs](https://learn.microsoft.com/nuget/nuget-org/id-prefix-reservation)). Prefixes can be marked public for open source projects with many contributors, which suits foundations like the .NET Foundation. There is no public API to list reservations. Trusted publishing covers GitHub Actions and GitLab CI, and policies can be owned by an organization ([docs](https://learn.microsoft.com/nuget/nuget-org/trusted-publishing)).

**RubyGems.** Names are flat and ownership is per gem. Organizations entered private beta in Feb 2026 with eight orgs onboarded and no public API yet ([RubyGems blog](https://blog.rubygems.org/2026/02/16/organizations-beta.html)). Trusted publishing and MFA requirements for popular gems already exist.

**Go.** There is no account-based registry. A module path is a URL (`github.com/org/repo` or a vanity domain like `go.opentelemetry.io` served by a `go-import` meta tag), so control of the domain or forge org is the namespace. proxy.golang.org caches modules and sum.golang.org is an append-only checksum log (from prior knowledge). For us, Go module prefixes map straight to forge orgs or foundation domains.

**Hex.** Public package names are flat with per-package owners; Hex organizations are mainly for private packages. Hex 2.6.0 (23 Oct 2026) added beta trusted publishing from GitHub Actions and reproducible package builds ([Elixir Forum](https://elixirforum.com/t/hex-v2-6-0-released/77133)).

**PyPI.** PyPI is the most important registry for the papers index, since NumFOCUS and PSF projects live there.

- *Organizations:* anyone can request one, but a PyPI admin approves it, and the requester's email domain must match the organization URL. Organizations are free for community projects and paid for companies. Projects an organization owns are listed on its public PyPI page, but membership is private and there is no API for org ownership ([org FAQ](https://docs.pypi.org/organization-accounts/org-acc-faq/)).
- *Namespaces are coming:* PEP 752, accepted 29 Jun 2026, lets an organization reserve a project-name prefix so only its accounts can upload under it ([PEP 752](https://peps.python.org/pep-0752/)). PEP 755, the draft review policy, was withdrawn on 2 Oct 2026 in favour of a PSF-maintained PyPI policy, which says paid orgs will not get priority ([PEP 755](https://peps.python.org/pep-755/)). Grants were proposed as open or restricted, with no public list of all grants. Foundations will be natural applicants, so we should watch for the first grants.
- *Publishing security:* 2FA is mandatory. Trusted publishing supports GitHub Actions, GitLab CI/CD (including self-managed in beta), Google Cloud and ActiveState. Since Nov 2025 an organization can own a pending trusted publisher, so new projects start out org-owned ([PyPI blog](https://blog.pypi.org/posts/2025-11-10-trusted-publishers-coming-to-orgs/)).
- *Forge link:* PEP 740 attestations (final, live since Nov 2024) attach a `publisher` object to each file. `Live records carry kind, repository, workflow and environment (the PEP's example also shows repository_owner_id, but PyPI does not serve it today)`, and the JSON API exposes a `provenance` URL per file ([PEP 740](https://peps.python.org/pep-0740), [PyPI attestations](https://docs.pypi.org/attestations/)). PyPI also marks project URLs as verified when trusted publishing proves them ([project metadata](https://docs.pypi.org/project_metadata/)). Together these name the source repository per release, which is the most precise registry → forge link of any registry here.

## System package managers

Distros trust their own packagers, not upstream foundations, so the useful link is upstream metadata inside each package rather than a namespace.

**apt (Debian, Ubuntu).** Packages in the main archive are uploaded by Debian Developers and Maintainers whose keys are in the Debian keyring; the archive signs `InRelease` files. There are no org namespaces. Foundations that ship their own builds run separate vendor repositories signed with their own key (for example Apache Cassandra's apt repo, from prior knowledge). The upstream tie is DEP-12 `debian/upstream/metadata`, which defines `Repository`, `Repository-Browse`, `Bug-Database`, `Donation`, `Funding`, `CPE`, `Registry` (e.g. a PyPI entry) and `Reference` DOIs ([DEP-12](https://dep-team.pages.debian.net/deps/dep12/)). Lintian flags packages missing `Repository`, and UDD aggregates these fields, so they are queryable at scale.

**yum/dnf (Fedora, EPEL, RHEL family).** Packagers sign in through the Fedora Account System, and RPMs and repo metadata are GPG-signed. Third-party repos (COPR, vendor `.repo` files) carry their own keys. The only upstream link is the spec file's `URL:` and `Source:` fields (from prior knowledge). There is no equivalent of DEP-12.

**Homebrew.** homebrew-core is curated by Homebrew maintainers. Third parties publish through taps, which are GitHub repos named `<org>/homebrew-<name>`, so a tap name is literally a GitHub org (e.g. `brew tap mongodb/brew`, from prior knowledge). Bottles built in Homebrew CI carry Sigstore-backed build provenance via GitHub artifact attestations ([Trail of Bits](https://blog.trailofbits.com/2024/05/14/a-peek-into-build-provenance-for-homebrew/)). formulae.brew.sh exposes formula JSON with `homepage`, `urls` and `license` (SPDX).

## Container and app stores

Flathub has the strongest domain-backed ownership check of any store; Docker Hub and Snap rely on manual or paid programs.

**Docker Hub.** Organizations are first come, first served. Trust badges come from three programs: Docker Official Images (curated by Docker), Verified Publisher (commercial), and Docker-Sponsored Open Source, which many foundation orgs such as `apache` use (from prior knowledge; badge list not re-checked today). Docker Content Trust (Notary v1) is being retired starting Aug 2025, and Docker recommends Sigstore or Notation for signing ([Docker blog](https://www.docker.com/blog/retiring-docker-content-trust/)). The forge link is the OCI annotation `org.opencontainers.image.source`, plus `.licenses` (SPDX) and `.vendor`. ecosyste.ms has a Docker index, so image → source repo can be checked at scale.

**Flathub.** App IDs are reverse-DNS. Verification proves control of the domain in the ID via `https://<domain>/.well-known/org.flathub.VerifiedApps.txt` or a `_flathub.<domain>` DNS TXT record, or by forge login for `io.github.*`, `io.gitlab.*`, `org.gnome.*` and `org.kde.*` IDs ([Flathub docs](https://docs.flathub.org/docs/for-app-authors/verification)). Codeberg is not a supported login provider. Each app's AppStream metainfo carries `project_license` (SPDX), `developer` and `url type="vcs-browser"`. An app ID like `org.libreoffice.LibreOffice` is therefore a verifiable foundation → app claim.

**Snap Store.** Publishers register snap names under an account. "Verified Account" badges go to institutions, foundations and companies that have partnered with Snapcraft, granted manually on request ([Snapcraft forum](https://forum.snapcraft.io/t/verified-accounts/34002)). `snapcraft.yaml` can declare `license` (SPDX) and `source-code`. The store API requires device headers and is less convenient to crawl.

## Tying registry records to forge orgs

There are six mechanisms, ranked from strongest to weakest evidence. The top three are cryptographic or verified by the registry; the bottom three are self-declared metadata.

| Rank | Mechanism | Where it exists | What it proves | Usable at scale? |
| --- | --- | --- | --- | --- |
| 1 | Trusted publishing (OIDC) and Sigstore provenance | npm, PyPI, crates.io, NuGet, RubyGems, Hex (beta), Homebrew bottles | This release was built by a workflow in repo `owner/name` on GitHub or GitLab | Yes for npm and PyPI (attestations are public); others store the policy privately |
| 2 | Shared domain verification | GitHub org, Maven groupId, Flathub app ID, Go vanity paths | The same party controls domain X on both sides | Yes, if we join on the foundation's domain |
| 3 | Forge-derived namespaces | Maven `io.github.*`, Flathub `io.github.*`, crates.io GitHub team owners, Homebrew taps, Go `github.com/...` paths | The namespace owner controls that forge account | Yes, it is in the name itself |
| 4 | Repository URL in package metadata | Every registry (`repository`, `<scm>`, `source_code_uri`, DEP-12, AppStream, OCI `source` label) | The publisher claims this repo | Yes; ecosyste.ms packages already exposes `repository_url` |
| 5 | Funding and contact files | `FUNDING.yml`, `funding.json`, `security.txt` | Who takes money or security reports | Partly |
| 6 | Manual badges | Docker Sponsored OSS, Snap Verified Account, NuGet prefix checkmark | The store vetted the publisher | Only by scraping web pages |

The OpenSSF guidance on trusted publishers recommends registries resolve repo and owner names to stable IDs to prevent rename attacks ([OpenSSF](https://repos.openssf.org/trusted-publishers-for-all-package-repositories)). We should do the same: store GitHub numeric org IDs next to logins where we can.

For fossfoundation the practical recipe is: start from the foundation's domain, find forge orgs that verify or list it (mechanism 2), then pull packages whose `repository_url` points into those orgs (mechanism 4), and mark the subset with provenance (mechanism 1) as high confidence.

## Standards encountered

Package URL (purl) and SPDX license IDs are the two standards worth adopting in our own schema now; the rest are context for what registries publish. Status details here are from prior knowledge unless linked above.

| Standard | What it marks | Seen in | Use for fossfoundation |
| --- | --- | --- | --- |
| Package URL (purl), ECMA-427 | A package or repo identity, e.g. `pkg:npm/%40openjs/foo`, `pkg:github/apache/kafka` | ecosyste.ms, SBOMs, OSV | Adopt as the project identifier key |
| SPDX license expressions | License of a package, e.g. `Apache-2.0 OR MIT` | npm, crates.io, NuGet, Homebrew, AppStream, OCI labels, Snap | Adopt for project license fields |
| SPDX documents (ISO/IEC 5962, SPDX 3.0) | Full SBOM for a release | GitHub dependency graph export, many build tools | Read only, via ecosyste.ms SBOM parser |
| CycloneDX (ECMA-424) | SBOM, also VEX and attestations | Maven and npm plugins, container scanners | Read only |
| Sigstore | Keyless signing and transparency log (Rekor) | npm, PyPI, Homebrew, GitHub attestations, recommended for Docker | Evidence for forge links |
| SLSA and in-toto | Build provenance format and levels | npm provenance, GitHub attestations | Evidence for forge links |
| OIDC trusted publishing | CI identity exchanged for a short-lived publish token | npm, PyPI, crates.io, NuGet, RubyGems, Hex | Evidence for forge links |
| OCI image annotations | `org.opencontainers.image.source`, `.licenses`, `.vendor` | Docker Hub, GHCR | Image → repo link |
| AppStream metainfo | App ID, license, developer, VCS URL | Flathub, Snap, distros | App → repo link |
| DEP-12 upstream metadata | Upstream repo, funding, registry IDs, DOIs | Debian | Distro → upstream link |
| DOAP | Project description in RDF, including repository and PMC | ASF (projects.apache.org) | Bulk source for ASF project repos |
| CITATION.cff and CodeMeta | How to cite software; DOIs, authors | GitHub, Zenodo, papers index | Add CITATION.cff to our repo |
| FUNDING.yml and funding.json | Where to fund a project | GitHub, FLOSS/fund | Cross-check our `donateurl` |
| security.txt (RFC 9116) | Security contact for a domain | Foundation websites | Optional foundation field |
| OSV, CPE, CSAF/VEX | Vulnerability identifiers and advisories | ecosyste.ms advisories, DEP-12 `CPE` | Out of scope for now |
| OpenSSF Scorecard | Automated repo security checks | deps.dev, many foundations' badges | Possible later metric |

One regulatory note: the EU Cyber Resilience Act defines "open-source software stewards", a legal role many foundations are now taking on for the software they host. That makes a foundation → namespace mapping more valuable in 2026–27, and worth flagging in the dataset's description.

## Integration plan with ecosyste.ms

Build a hand-verified crosswalk for 5 pilot foundations first, then use ecosyste.ms to expand it and measure coverage. Every ecosyste.ms call carries `mailto=` a polite email.

**Proposed fields** (refines section 4.2 of the handoff). Each entry records how we know it, so the data stays traceable per CONTRIBUTING.

| Field | Shape | Example | ecosyste.ms lookup |
| --- | --- | --- | --- |
| `codeOwners` | list of `{host, login, id?, evidence, source}` | `{host: GitHub, login: apache, evidence: domain-verified}` | repos `/hosts/{host}/owners/{login}` |
| `codeHosts` | list of self-hosted forge base URLs | `https://gitlab.eclipse.org` | repos `/hosts` |
| `packageNamespaces` | list of `{registry, namespace, evidence, source}` | `{registry: repo1.maven.org, namespace: org.apache}` | packages `/registries/{r}/namespaces/{ns}` |
| `appIds` | list of `{store, id}` | `{store: flathub, id: org.libreoffice.LibreOffice}` | none yet; Flathub API direct |
| `containerOrgs` | list of `{registry, org}` | `{registry: hub.docker.com, org: apache}` | packages (Docker registry) |
| Project `purl` / `repository_url` | purl string; URL | `pkg:github/apache/kafka` | repos `/repositories/lookup?purl=` |

`evidence` takes one of: `domain-verified` (GitHub badge, Maven DNS, Flathub), `forge-derived` (namespace contains the forge login), `provenance` (trusted publishing seen), `self-declared` (listed on the foundation's own site), `badge` (store program).

**Build steps**

1. Agree the field shapes above, and whether they live on the foundation record or in a `_data/crosswalk/` file (open question from the handoff).
2. Hand-seed the pilot foundations (asf, python, numfocus, openjsf, eclipse) from their own websites and their PyPI Organization pages, recording sources.
3. Write a small Python 3.12 + uv tool that, for each seeded org and namespace, calls ecosyste.ms repos and packages and reports counts and unmatched items. It needs to run from a machine or GitHub Action that can reach ecosyste.ms, since this cloud environment cannot.
4. Expand: for each org's repositories, look up packages whose `repository_url` points into that org, and propose new `packageNamespaces` for human review.
5. Use the papers index on the resulting purls to count research mentions per foundation, and sponsors on the GitHub logins.
6. Publish the crosswalk as a stable JSON export and offer it to Andrew Nesbitt, since "which foundation stewards which orgs and namespaces" is the piece ecosyste.ms lacks.

Outside ecosyste.ms, the cheapest extra signals are the GitHub REST `is_verified` flag (one call per org), PyPI attestation publisher fields (the source repository per release), npm provenance, and DEP-12 `Repository` fields via UDD.

## Open questions

- [ ] Should the crosswalk cover every platform in this doc, or start with GitHub, npm, Maven Central, PyPI and Docker Hub, which cover most pilot foundations? **SC: **Start with your list of recommended sites, plus add RubyGems; our focus is finding a good-enough generic set of fields/evidence that we can use for every foundation and source platform or registry.
- [ ] PyPI is in scope (confirmed 28 Oct). Once PyPI opens PEP 752 namespace grants, should we record foundation grants as packageNamespaces and check them against PyPI's policy? **SC: ** yes, and writeup a brief document comparing the specific fields, how they're documented, and how we collect evidence to assess the truth of a connection with PyPi, so that we can confirm the larger meaning of fields and evidence can match across registries.
- [ ] Can we get a GitHub Action or local machine with access to ecosyste.ms for live sampling? This cloud environment's network policy blocks it. **SC: **I have added Claude for Chrome, please test using that.
- [ ] Do you want the EU CRA "steward" angle included in the dataset description? **SC: **Yes; review the data fields in the ShaneCurcuru/asf-cra-attestations repository, and analyze the fields in the ORC WG light-weight template that asf-cra-attestations uses to evaluate connections between our work here and the CRA's attestations requirements.

## Sources

All fetched on 2026-10-28.

- GitHub: [org domain verification](https://docs.github.com/en/organizations/managing-organization-settings/verifying-or-approving-a-domain-for-your-organization), [GraphQL orgs reference](https://docs.github.com/en/graphql/reference/orgs)
- GitLab: [enterprise users and domain verification](https://docs.gitlab.com/user/enterprise_user)
- npm: [classic tokens revoked, Dec 2025](https://github.blog/changelog/2025-12-09-npm-classic-tokens-revoked-session-based-auth-and-cli-token-management-now-available/), [trusted publishing GA](https://github.blog/changelog/2025-07-31-npm-trusted-publishing-with-oidc-is-generally-available/)
- Maven Central: [namespace registration](https://central.sonatype.org/register/namespace/)
- crates.io: [development update, Jan 2026](https://blog.rust-lang.org/2026/01/21/crates-io-development-update)
- NuGet: [ID prefix reservation](https://learn.microsoft.com/nuget/nuget-org/id-prefix-reservation), [trusted publishing](https://learn.microsoft.com/nuget/nuget-org/trusted-publishing)
- RubyGems: [organizations beta](https://blog.rubygems.org/2026/02/16/organizations-beta.html)
- Hex: [Hex v2.6.0 release](https://elixirforum.com/t/hex-v2-6-0-released/77133)
- PyPI: [trusted publishers for orgs](https://blog.pypi.org/posts/2025-11-10-trusted-publishers-coming-to-orgs/), [project metadata verification](https://docs.pypi.org/project_metadata/)
- Debian: [DEP-12](https://dep-team.pages.debian.net/deps/dep12/)
- Homebrew: [build provenance](https://blog.trailofbits.com/2024/05/14/a-peek-into-build-provenance-for-homebrew/)
- Docker: [retiring Docker Content Trust](https://www.docker.com/blog/retiring-docker-content-trust/)
- Flathub: [verification](https://docs.flathub.org/docs/for-app-authors/verification)
- Snap: [verified accounts](https://forum.snapcraft.io/t/verified-accounts/34002)
- OpenSSF: [trusted publishers for all package repositories](https://repos.openssf.org/trusted-publishers-for-all-package-repositories)
