---
title: FOSS Foundation Leadership, a Cross-Foundation Analysis
identifier: leadership-analysis
section: reports
asOf: 2026-07-26
source: _leadership collection (86 foundations)
---
# FOSS Foundation Leadership: a Cross-Foundation Analysis

This report summarises the `_leadership` collection: the named board directors, officers, and paid staff of the foundations in this directory. It covers 86 foundations and 1,161 individuals as of 2026-07-26. Every figure derives from each foundation's own published pages; absent data is recorded as null rather than guessed.

## Who publishes their leadership

Of 86 foundations, 76 publish a current leadership roster and 10 do not. The 10 without a public roster are freesoftwaresupport, idcommons, kernel, kuali, lfcharities, olpc, opencollective, raspberrypi2, wordpress, and xiph. Two of these are legal-entity artefacts rather than true gaps: raspberrypi2 is the Raspberry Pi Foundation's separate North America 501(c)(3), whose own directors are not published (attributing the UK trustees would be incorrect), and several others publish governance only through IRS Form 990 rather than a web page.

## Board size

Across the 74 foundations that publish a board, board size runs from 1 to 21 directors, with a median of 7 and a mean of 8.4. The median of 7 holds steady across both volunteer-run and staffed foundations. The largest boards belong to the industry-consortium foundations (sustaining-member or corporate-seat models); the smallest are single-project foundations run by a founder-led council.

## Paid staff versus volunteers

The collection records 620 board-director roles, 437 paid-staff roles, 237 officer roles, and 114 explicitly volunteer roles. 48 of 86 foundations list at least one paid staff member. The split is bimodal: a set of well-resourced foundations publish substantial staff pages (Linux Foundation, Eclipse, Creative Commons, KDE, OSI), while a larger set are governed entirely by unpaid volunteers who hold both director and officer roles. Paid-staff classification is stated verbatim where a foundation uses an explicit employment label and inferred at lower confidence where only a "Staff" heading is given.

## Field coverage, and the case for annotated freshness

Names and roles are near-universal at full confidence. The optional fields are sparse and uneven: 50% of individuals carry a published bio, 17% carry any per-person contact, and 13% carry a term date. Term dates in particular are rarely stated on leadership pages; tenure is better reconstructed from dated roster snapshots over time than from the current page. This unevenness is exactly why every record carries an `asOf` date, every source a `retrieved` date, and every fact a `confidence` score: the freshness and reliability of each field travels with the data rather than being assumed uniform.

## Cross-foundation figures

Entity resolution across all rosters identifies 19 individuals who hold leadership roles at more than one foundation, a small but connective core of the FOSS governance world. The full Who's Who registry, with per-person identifiers, is available alongside this collection.

## Method

Rosters were crawled from each foundation's own site (with a small number recovered from the Internet Archive or Wikipedia where the live site was unreachable, tagged accordingly at reduced confidence). Extraction never fabricates: absent fields are null, advisory boards and project-level roles are excluded from the leadership definition, and every person links to the source page the fact came from. A deterministic weekly refresh check re-hashes each roster page and surfaces only the foundations whose pages have changed, keeping re-verification proportionate.
