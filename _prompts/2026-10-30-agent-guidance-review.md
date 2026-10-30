# Agent guidance review and AGENTS.md draft

2026-10-30 · Shane Curcuru, with Claude

Status: decided

## Prompt

Shane, 2026-10-30:

> Help me improve my agents.md and other agentic standards to ensure our development best
> matches my human intentions and goals. Review local file
> _prompts/2026-10-30-repo-technical.md, and also review any agent.md files used with this
> repository. Suggest improvements to your use of this file, and draft an agents.md for this
> repository.

Shane shared `_prompts/2026-10-30-repo-technical.md` later the same day. Its review is the
next section, and its rules are folded into the draft AGENTS.md.

## Review of 2026-10-30-repo-technical.md

This file is the clearest statement of Shane's technical standards, and it improves on the
current AGENTS.md: the persona is gone, and it adds licensing, dependency, tool placement,
attribution, and taxonomy rules. Suggestions:

### How to use it

- **Merge it into AGENTS.md rather than keeping it separate.** Agents reliably load only
  `AGENTS.md` (and `CLAUDE.md` for Claude). A rule that lives only in a dated `_prompts/` file
  is read only when an agent happens to open it, and links aren't followed reliably. Standing
  rules belong in AGENTS.md. Keep this file in `_prompts/` as the dated record of the
  prompt, with `Status: merged into AGENTS.md`.
- **Change standards with a PR to AGENTS.md** from now on, with the reasoning in a new dated
  `_prompts/` note. Two copies of the same rules will drift, the same way AGENTS.md and the
  commit history already have.

### Corrections and conflicts

1. **SPDX comment syntax.** `//` is a comment only in C-like languages. This repository's code
   is Python, Ruby, Liquid/HTML and Markdown, so `#` and `<!-- -->` are needed, and existing
   Ruby files already use `# SPDX-License-Identifier: Apache-2.0`. JSON and CSV can't hold
   comments at all. The [REUSE](https://reuse.software) spec (FSFE, widely used) covers these
   cases with a `REUSE.toml` file, and `reuse lint` checks it. The draft uses that.
2. **Python 3.14+ vs. fdncrosswalk.** The tool merged two days ago declares
   `requires-python = ">=3.12"`. The draft applies 3.14+ to new tools and raises existing
   tools in their own PR, so no merged code silently falls out of policy.
3. **Ruby 3.4+ vs. `.ruby-version` 3.3.0.** The pin is already blocking `bundle` on 3.3.6.
   Raising it to 3.4 also fixes that problem, but it changes the GitHub Pages build and
   `Gemfile.lock`, so it should be its own PR.
4. **"Use chruby"** only tells people how to switch Ruby versions; agents and CI don't use it.
   I'd move it to CONTRIBUTING.
5. **"Follow rubocop" and "popular linting"** have no config or command behind them yet.
   Running rubocop with default rules on the existing Ruby would produce exactly the
   whitespace churn the "surgical diffs" rule forbids. The draft says to lint only changed
   lines; adding `ruff` and `.rubocop.yml` configs would make the rule checkable.
6. **"Posted by Claude on behalf of @shanecurcuru"**: it should say where this goes. The draft
   applies it to PR descriptions, issues and comments, and in commits places it just above
   the trailers, because git only recognizes trailers in the last paragraph. An `@` mention
   in a commit message or PR body notifies you each time; drop the `@` if that's noisy.
7. **"Apache Magpie convention"**: I couldn't find a reference for this, so the draft cites
   only the ASF generative tooling guidance. A link would help agents follow it exactly.
8. **The external-content rule** still has no body. The draft keeps your wording and adds
   what counts as external and what to do with it.

### Already consistent

Category A dependencies: the current dependencies (jekyll, just-the-docs, jsonschema,
hatchling, pytest, nokogiri) are all MIT-licensed, which is Category A. The taxonomy list
(OpenMetadata, OpenSSF, NTEE, taxonomy.ecosyste.ms) and "multiple formats" are now in the
draft's data rules.

## What exists today

- `AGENTS.md` (43 lines): persona, platform and tools, design constraints, data schemas,
  git rules, and a heading for the external-content rule.
- `_prompts/AGENTS.md` (5 lines): the file naming rule for this directory.
- No `CLAUDE.md`, `.github/copilot-instructions.md`, `.cursor/rules`, or `GEMINI.md`.
- Human rules that agents also need are in `CONTRIBUTING.md` and
  `.github/PULL_REQUEST_TEMPLATE.md`.

## Findings

### 1. Claude Code probably isn't reading AGENTS.md at all

Claude Code loads `CLAUDE.md`, not `AGENTS.md`. With no `CLAUDE.md` in the repository,
Claude sessions only follow AGENTS.md when they happen to open it. The commit history shows
the drift: commit `2fa7706` (PR #77) carries `Co-Authored-By:` trailers, which AGENTS.md
forbids, while the commits in PR #78 correctly use `Generated-by: Claude Code`.

**Fix:** add a one-line `CLAUDE.md` containing `@AGENTS.md`, which imports it. Codex,
Copilot's coding agent, and Cursor read `AGENTS.md` directly. Gemini CLI needs
`contextFileName: AGENTS.md` in its settings, or a `GEMINI.md` with the same import.

### 2. It says how to work, but not what the work is for

The persona ("expert open-source maintainer and academic researcher") tells an agent who
to be, but not what Shane is trying to achieve, who the readers are, or which goal wins when
two conflict. Agents follow concrete priorities better than personas. The draft replaces
the persona with the site's purpose, audience, and a ranked list of goals: accuracy,
fairness to foundations, standards-based data, then reviewable changes.

### 3. Nothing tells an agent when to stop and ask

"Ask the user" appears only for out-of-scope fixes and tool growth. The changes Shane most
wants to see first are not listed: new data fields (CONTRIBUTING already asks for an issue
first), descriptive text about a foundation, new dependencies or workflows, published API or
URL changes, and data about people. The draft adds an explicit "stop and ask" list and asks
the agent to restate the goal and its reading of the ask before starting.

### 4. Commands are named only as tools, not as commands

"Baseline first: run the existing test suite" has no suite to point to. There are three
separate checks: `bundle exec jekyll build` (the only CI check), the minitest files in
`assets/ruby/test/` run one at a time, and `uv run pytest` in `assets/python/fdncrosswalk`.
The draft lists them. I ran them on 2026-10-30 in a clean container:

- `money_filter_test.rb`: 4 runs, 0 failures.
- `sponsor_utils_test.rb` and `sponsor_archive_test.rb`: cannot start, because `nokogiri`
  and `public_suffix` aren't in the `Gemfile`.
- fdncrosswalk: 41 tests passed, and `fdncrosswalk validate` passed.
- `bundle exec jekyll build`: couldn't run, because `.ruby-version` pins exactly `3.3.0`
  and the container has 3.3.6.

Both of the last two problems will trip any agent. Worth deciding: add the scraper gems to
a `Gemfile` group, and relax `.ruby-version` (or document the needed version manager).
"Use chruby" and "follow rubocop" can go, since there's no rubocop config and agents don't
choose the Ruby version manager.

### 5. Data and privacy rules live outside AGENTS.md

The rules that matter most for this dataset are in CONTRIBUTING, in chat history, or only in
Claude's project memory: trace every fact to the organization's own site, no guessing,
factual not marketing text, `identifier` always means the `_foundations` id, complement
ecosyste.ms rather than copying it, CC0 for exports and Apache-2.0 for code, and never commit
an email address (`ECOSYSTEMS_MAILTO` instead). The draft brings them into AGENTS.md, so
every agent sees them, not just Claude in this project.

### 6. No map of generated files

Several paths are written by tools (`api/v1/crosswalk/`, `history/sponsorships/`,
`_data/sponsorships/*.json`, `_foundations/list.json`). An agent that hand-edits them gets
overwritten on the next run. The draft adds a repository map that marks each path as hand
edited or generated, and by which tool.

### 7. The external-content rule has a heading but no body

The rule says it is absolute but doesn't say what counts as external or what to do. For this
repository the risky inputs are foundation websites, registry and ecosyste.ms responses,
scraped files, and PRs and comments from forks (PR #58 is an example of a large contributed
dataset). The draft names them and says to quote any embedded instruction to Shane instead
of acting on it.

### 8. Decisions live in chat and Claude memory instead of the repository

Decisions like "`platformId`, not `identifier`" or "keep crosswalk work separate from the
leadership PR" are recorded in Claude's project memory and in Claude Docs. Other agents and
contributors can't see them. The draft asks agents to write plans and decisions into
`_prompts/`, and the updated `_prompts/AGENTS.md` adds a header with a `Status:` line, the
original prompt, and a **Decisions** section. The 2026-10-28 plans already follow most of
this shape.

## How I'll use these files differently

- Read `AGENTS.md` and the relevant `_prompts/` plan at the start of every repository task,
  even before `CLAUDE.md` exists.
- Restate the goal and my reading of the ask in the first reply and in each PR.
- Use `Generated-by: Claude Code` on every commit to this repository, instead of the
  `Co-Authored-By:` line my tooling adds by default.
- Save decisions to the relevant `_prompts/` plan in the PR, and keep Claude memory for
  things that don't belong in a public repository.
- Treat the "stop and ask" list as the line between work I start on my own and work I bring
  to you first.

## Proposed files

- `AGENTS.md`: full rewrite (draft alongside this document).
- `CLAUDE.md`: new, one line, `@AGENTS.md`.
- `_prompts/AGENTS.md`: expanded with a document header and rules.
- This document, as `_prompts/2026-10-30-agent-guidance-review.md`.
- `_prompts/2026-10-30-repo-technical.md`: Shane's file as given, with a `Status: merged into AGENTS.md` line added.

## Open questions

1. ~~Should agents ever push directly to `main`?~~ Decided, see below.
2. ~~Should tests be forbidden from using the network?~~ Decided, see below.
3. ~~Fix the Gemfile and `.ruby-version` problems in this PR or a separate one?~~ Decided, see below.
4. ~~Add a `GEMINI.md` or Copilot instructions file?~~ Decided, see below.
5. ~~Adopt REUSE for per-file licensing?~~ Decided, see below.
6. ~~Merge `2026-10-30-repo-technical.md` into AGENTS.md?~~ Decided, see below.

## Decisions

- 2026-10-30: agents always use a PR, never push to `main` (Shane). AGENTS.md already says so.
- 2026-10-30: tests must not use the network, for now (Shane). Rationale: fast, repeatable tests that don't depend on or load the sites we cite. This may change later (for example opt-in integration tests) by a recorded decision. Existing tests already comply: the Ruby tests stub `SponsorArchive.http_get`, and the fdncrosswalk tests make no network calls.
- 2026-10-30: environment fixes (Gemfile scraper gems, `.ruby-version`, Ruby 3.4, linter configs) go in a separate PR, prepared after this agent-guidance PR is done (Shane).
- 2026-10-30: keep only `AGENTS.md` and `CLAUDE.md` (which imports AGENTS.md); no `GEMINI.md` or Copilot instructions file (Shane).
- 2026-10-30: adopt REUSE (`REUSE.toml`, `reuse lint`) and list it among preferred standards (Shane). Adding `REUSE.toml` and headers to existing files belongs in the environment PR. Note: the `reuse` tool itself is GPL-3.0-or-later, so run it as an external tool (`uvx reuse lint`, or in CI), not as a project dependency, to stay within the Category A rule.
- 2026-10-30: merge `2026-10-30-repo-technical.md` into AGENTS.md and mark it merged (Shane). Standing rules change by PR to AGENTS.md from now on.
