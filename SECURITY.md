# Security Policy

## Reporting a vulnerability

If you believe you have found a security vulnerability in this repository
(website, content, or its automation), please do **not** open a public issue.

- Preferred: use **private vulnerability reporting** in GitHub —
  `Security` tab → `Reporting a vulnerability` (requires the repository
  maintainer to enable it; see *Maintainer follow-ups* below).
- Alternatively, email the maintainer at **asf@shanecurcuru.org**
  (Shane Curcuru, Apache Director).

Acknowledgement is expected within a few business days; a fix or a
documented rationale is expected before any public disclosure.

## Threat model

This repository is a static Jekyll website (the FOSStealth Foundation
technical content) plus its GitHub Actions automation. The realistic
security surface is therefore:

1. **Dependency supply chain** — the Ruby gems used to build the site and
   the GitHub Actions used in CI.
2. **CI/CD workflow integrity** — who can change the workflows, and what
   those workflows are allowed to do.
3. **Repository content** — generated pages and data (`_data/`, `_pages/`)
   rendered into the public site.

There is no server-side application code, no user input processing, and no
npm/Node tooling (OpenAPI generation is implemented in Ruby under
`assets/ruby/`).

## How we keep it safe

| Control | Where | What it does |
|---|---|---|
| Committed `Gemfile.lock` | repository root | Every build (local and CI) installs the *exact* gem versions that were audited, rather than re-resolving "latest matching" versions at build time. This makes the build reproducible and turns "which version is actually in use" into a reviewable diff. |
| Dependabot | `.github/dependabot.yml` | Weekly dependency-update pull requests for the `bundler` ecosystem (gems) and for `github-actions` versions. Updates require maintainer review before merge — no unreviewed code is ever introduced automatically. |
| SHA-pinned Actions | `.github/workflows/*.yml` | Every `uses:` in the workflows is pinned to a commit SHA with a `# vX.Y.Z` comment. A tag (e.g. `@v5`) is a moving target: a maintainer of that action could republish a tag to new code, and the workflow would silently run it. SHA pinning means the exact code that runs in CI is the code reviewed in the diff. Dependabot keeps the SHAs current. |
| CodeQL scanning | `.github/workflows/codeql.yml` | Static analysis for known vulnerability patterns in the repository source (Ruby) on every PR to `main` and weekly. Findings surface as PR checks and in the `Security` tab. |
| Least-privilege CI token | `deploy-pages.yml` `permissions:` | The GitHub Actions token is scoped to the minimum needed (`contents: read`, `pages: write`, `id-token: write`) — the workflow cannot read or modify repository contents, secrets, or other repositories. |
| Deploy guard | `deploy-pages.yml` `if:` + `environment:` | Production deploys only run from `main` (never directly from PR builds) and go through the `github-pages` deployment environment, which supports required reviewers. |
| CODEOWNERS | `.github/CODEOWNERS` | All changes — especially anything under `.github/` — require approval from the named maintainer. Pair with branch protection (see below) to make this a hard gate. |
| PR template | `.github/PULL_REQUEST_TEMPLATE.md` | Reminds contributors to keep `Gemfile.lock` current and to regenerate derived content, so the audited state and the published state stay in sync. |

### Why `package-lock.json` was removed

The repository previously contained a `package-lock.json` with **no**
`package.json`. Its top-level dependency (`@openapi-contrib/
json-schema-to-openapi-schema`) is not used by any code in this
repository — OpenAPI generation is implemented in Ruby
(`assets/ruby/openapi_builder.rb`) — so the lockfile was orphaned.
`npm audit` reported 2 high-severity vulnerabilities in its `js-yaml`
dependency (GHSA-mh29-5h37-fv8m prototype pollution,
GHSA-h67p-54hq-rp68 denial of service), so it was deleted rather than
patched: an untracked lockfile also offers no guarantee the pinned
versions were ever actually used.

### Routine dependency hygiene

- **After any `Gemfile` change:** run `bundle lock` (Ruby 3.3.0 per
  `.ruby-version`) and commit the regenerated `Gemfile.lock`.
- **Periodically (or after an advisory):** run
  `bundle add bundler-audit --dev && bundle exec bundle audit` to check
  installed gems against the Ruby advisory database.
- **Dependabot PRs:** review the changed versions, check the advisory/
  changelog links Dependabot attaches, and confirm the lockfile diff is
  what you expect. Merge failures in the Pages build are the primary
  signal for a breaking bump.

## Maintainer follow-ups (require repository admin settings)

These cannot be set from a pull request. Recommended, in rough priority
order:

1. **Branch protection on `main`** (Settings → Branches):
   - Require pull request reviews before merging, *including* for
     maintainers.
   - Require "Require review from Code Owners" (activates `.github/CODEOWNERS`).
   - Require status checks to pass before merging: the Pages `build` job
     and the CodeQL scan.
   - Restrict who can push directly to `main` (ideally no one — all
     changes via PR).
2. **Code Security settings** (Settings → Code security and
   analysis):
   - Ensure **Code scanning** is enabled (the workflow provides the
     scans once the check is permitted).
   - Enable **private vulnerability reporting** so reports come in
     privately instead of as public issues.
3. **Dependabot settings** (Settings → Code security and analysis →
   Dependabot):
   - Choose the update policy. Suggested start: security updates only,
     pull-request (no auto-merge) until a comfortable review cadence is
     established; then consider auto-merging *security-only* updates for
     `github-actions` and `bundler` with branch protection above in
     place.
4. **Secret scanning and push protection** (Settings → Code security and
   analysis): so accidentally committed credentials are flagged and
   blocked rather than published to a fork.

## Status

- [x] `Gemfile.lock` committed; audited clean against the Ruby advisory
      database (2026-09-27)
- [x] Orphaned `package-lock.json` removed (2 high-severity findings)
- [x] Dependabot configured (bundler, github-actions; weekly)
- [x] All Actions pinned to commit SHAs
- [x] CodeQL scanning enabled (ruby)
- [ ] Branch protection + required checks (admin)
- [ ] Code scanning / private vulnerability reporting enabled (admin)
- [ ] Dependabot merge policy (admin)
- [ ] Secret scanning + push protection (admin)
