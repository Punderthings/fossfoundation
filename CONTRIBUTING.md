# How to Suggest Changes

:sparkles: :tada: Thanks for contributing! :tada: :star2:

FOSSFoundation.info is a public, citable directory of non-profit FOSS foundations, for
open source practitioners and academic researchers. It records the organizations, the
people who lead them, and how they are funded. Data about code, packages, repositories,
and similar technical details is left to [ecosyste.ms](https://ecosyste.ms/) and similar
services, which we link to. Read [Data Philosophy](https://fossfoundation.info/data) for
the datasets we keep, and the [Foundation model](https://fossfoundation.info/fdnmodel) for
what a foundation record holds and which organizations qualify.

## Licensing

By contributing, you agree that your contribution is licensed as follows:

- Code, site pages, and prose: [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
- New datasets and data exports (for example `api/v1/crosswalk/`): [CC0-1.0](https://creativecommons.org/publicdomain/zero/1.0/).
- Existing data files: Apache-2.0, as in [LICENSE](LICENSE), unless the maintainers decide otherwise.

Every file's license is declared following the [REUSE](https://reuse.software)
specification, in an SPDX header or in [`REUSE.toml`](REUSE.toml).

## Rules For Data

- **Cite a source you checked.** Every new or changed fact needs a URL you actually
  checked, preferably on the organization's own website. If you can't verify a value,
  leave the field out. No guessing, and no filling fields from memory.
- **Keep descriptions factual.** The Markdown sentence at the end of each foundation file,
  and any other descriptive text, is factual and neutral, never marketing.
- **Officers get a say.** Changes to the descriptive text about a foundation should come
  from a GitHub user clearly associated with that foundation's board or officers, or
  include a link to the foundation's own site that supports the change. Factual data is
  easy to verify with a link; descriptive text is where each organization's officers
  should have a say.
- **Where updates come from.** Most data updates arrive either from a new run of our
  scrapers, or from members of an organization telling us about a change, or, more
  rarely, correcting our data directly.
- **No personal information.** Never add personal email addresses, phone numbers, or home
  addresses, unless that person explicitly asked to share their own.

## Issues vs. PRs

- A specific fix or improvement: please open a GitHub Pull Request with the change.
- A larger change, a new idea, or new data fields or schema changes: please open a GitHub
  Issue to **start** a discussion before doing more work.

## How To Update Existing Data

- Make sure you are adding or updating accurate data, following the rules above.
- In the PR, say where you checked each changed fact. (How to record when each field was
  last verified is still an open design question.)
- Submit a GitHub PR for the `_foundations/<identifier>.md` file.

## How To Add A New Foundation

All the foundation data is stored in `_foundations/`, one file per foundation, so adding a
new foundation is as simple as creating a file in that folder in the right format.

- Copy [`_data/foundation-template.md`](_data/foundation-template.md) to `_foundations/`
  as the base of your new file.
  - `cp _data/foundation-template.md _foundations/`
- Decide on the shortest and most common name used for the foundation that would still be
  unique in the current open source space.
- Lowercase the name and remove any non-letter characters. The result is the foundation's
  `identifier`, used as its filename and to link it to every other dataset.
- Rename the copy to `_foundations/<identifier>.md` and fill in as many fields as you can
  verify (no guessing!)
  - You will find descriptions for each field in [`_data/foundations-schema.json`](_data/foundations-schema.json).
  - Use [Schema.org NonprofitType](https://schema.org/NonprofitType) values for
    `nonprofitStatus`, or leave it blank if you're not sure.
  - Leave both `---` YAML document separators, and replace the body of the Markdown
    document with a single factual sentence that describes the foundation.
- Submit your PR!
- If the foundation hosts multiple open source projects, feel free to add a projects
  listing for it as a separate PR. See examples in [`_pages/projects.md`](_pages/projects.md)
  and scrapers in [`assets/ruby/scrapers.rb`](assets/ruby/scrapers.rb).

## Other Datasets

- **Sponsorship programs** live in `_sponsorships/<identifier>.md`; see
  [Sponsorship Models](https://fossfoundation.info/sponsorships).
- **Non-foundation entities**, such as projects with a fiscal host, live in `_entities/`;
  see [Non-Foundation FOSS Entities](https://fossfoundation.info/entities).
- **Platform crosswalk** files, listing a foundation's accounts on code hosts and package
  registries with evidence, live in `_data/crosswalk/<identifier>.json`; see
  [Platform Crosswalk](https://fossfoundation.info/crosswalk).
- **Hosted projects** are listed in `_data/projects-<identifier>.csv`; see
  [Software Projects Hosted At Foundations](https://fossfoundation.info/projects).

Some files are generated by our tools and must not be edited by hand, including
`_data/sponsorships/*.json`, `history/sponsorships/`, `api/v1/crosswalk/`, and
`_foundations/list.json`. To change them, change their source or tool, regenerate, and
commit both. [AGENTS.md](AGENTS.md#repository-map) has the full map of which files are
generated and by what.

## How To Run And Check Locally

The website is built with Jekyll; the Ruby version is in [`.ruby-version`](.ruby-version).

```sh
bundle install
bundle exec jekyll serve    # local preview
bundle exec jekyll build    # required check; must pass before a PR
uvx reuse lint              # license check
```

If you change `_data/crosswalk/`, also run `uv run fdncrosswalk validate` from
`assets/python/fdncrosswalk`. The commands for each tool and its tests are listed in
[AGENTS.md](AGENTS.md#commands).

## Opening A PR

Fill in every section of the [pull request template](.github/PULL_REQUEST_TEMPLATE.md),
and tick only the checklist items you actually did. A maintainer reviews and merges every
change.

## Using An AI Agent

You are welcome to use an AI coding agent. Agents working in this repository follow
[AGENTS.md](AGENTS.md), and you remain responsible for what you submit. Following the ASF
convention for generative tooling, commits written with an agent end with a
`Generated-by:` trailer naming the tool, for example `Generated-by: Claude Code`.

Reminder: Please be [excellent to each other](CODE_OF_CONDUCT.md)!
