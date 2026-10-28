# fdncrosswalk

Checks which accounts each foundation controls on code hosts and package registries, using the
evidence recorded in [`_data/crosswalk/`](../../../_data/crosswalk/) and the schema in
[`_data/crosswalk-schema.json`](../../../_data/crosswalk-schema.json). It also builds the
ecosyste.ms lookups for those accounts, writes the public exports, and fills the purl columns of the
project CSVs. Field meanings and the standards they map to are documented at
[fossfoundation.info/crosswalk](https://fossfoundation.info/crosswalk) (`_pages/crosswalk.md`).

## Data model

Each `_data/crosswalk/<foundation>.json` lists **accounts**: an org, namespace or owner on one
platform (GitHub, GitLab, Codeberg, npm, Maven Central, PyPI, Docker Hub, RubyGems). Every account
has one or more **evidence** items, each with a type, a source URL and the date it was checked. An
account can name a hosted `project` when it belongs to that project rather than to the foundation,
and GitHub accounts carry `platformId`, the org's stable numeric id (the ecosyste.ms owner `uuid`).

An optional **packages** list holds purls (e.g. `pkg:pypi/numpy`) with their `codeRepository` and
their own evidence. The first package listed for a project is copied to the `purl` and
`codeRepository` columns of `_data/projects-<foundation>.csv` by `sync-csv`.

Confidence is computed from the evidence types, never stored:

| Confidence | When |
| --- | --- |
| confirmed | `steward-declared` (the foundation's own site names it), `platform-verified` (the platform checked a domain or identity), or `human-attested` recorded by a login listed in `_data/attestors.json` |
| probable | `profile-claim`, `program-badge`, `publish-provenance`, `repository-link`, `namespace-convention`, or `human-attested` by anyone else |
| unconfirmed | only `name-match` |
| rejected | any `contradiction`, unless a listed attestor's later `human-attested` item sets `supersedes`; kept so look-alike accounts are not added again |

A level is also reported as **stale** when every item supporting it is past its freshness date:
`validThrough` if given, otherwise one year after `observed` for `steward-declared` and
`human-attested`, and 90 days for the rest.

## Use

Python 3.12+ and [uv](https://docs.astral.sh/uv/):

```sh
cd assets/python/fdncrosswalk
uv sync --group test
uv run fdncrosswalk validate          # check every crosswalk file against the schema
uv run fdncrosswalk report            # foundation, confidence (stale), platform, kind, name; then packages
uv run fdncrosswalk urls              # ecosyste.ms lookups for every non-rejected account and package
uv run fdncrosswalk export            # write api/v1/crosswalk/ (JSON-LD, context, vocab, stewards.jsonl)
uv run fdncrosswalk sync-csv          # fill purl and codeRepository in _data/projects-*.csv
uv run fdncrosswalk probe hub.docker.com apache   # suggest evidence from a registry API
uv run fdncrosswalk probe pypi.org pyperf
uv run fdncrosswalk probe npmjs.org @psf
uv run pytest
```

Every ecosyste.ms URL carries `mailto=` a polite email, read from the `ECOSYSTEMS_MAILTO`
environment variable (or `--mailto`), so requests use the
[polite pool](https://ecosyste.ms/api). Never commit the address itself.
Probes only suggest evidence; review it and copy what holds up into the crosswalk file.

`--today YYYY-MM-DD` judges staleness as of that date. Exports are published under CC0-1.0.

The library API is `fdncrosswalk.load_dir`, `assess`, `confidence`, `load_attestors`, `lookup_urls`,
`package_lookup_urls`, `write_exports` and the functions in
`fdncrosswalk.probes`, which take a `fetch` callable so they can run against recorded responses.
Tests run offline from `tests/fixtures/`, which hold trimmed real responses recorded on 2026-10-28.
