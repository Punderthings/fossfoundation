# Clean up nonprofitStatus values and add an enum

2026-11-15 · Shane Curcuru, with Claude

Status: decided (2026-11-15); implemented in #110

## Prompt

From [the derive-lists plan](2026-11-15-derive-lists-from-schemas.md), open question 5:
"**`nonprofitStatus` enum.** Leave it for a separate data cleanup, or start that cleanup
now? **SC:** Yes, do that as a PR as noted in this plan; this is an important cleanup to do."

## Today

`nonprofitStatus` is required, documented as "Specific type of non-profit; types:
https://schema.org/NonprofitType", and has a `TODO: enum` comment. Two templates
hard-code values: the US-dollar check on foundation pages (any value containing
`Nonprofit501`, or `Nonprofit527`), and the 501(c)(3) and 501(c)(6) columns on the
categories page, whose third column, "Non-US Nonprofits", is everything else.

Of 95 records, 75 use `Nonprofit501c3` or `Nonprofit501c6`, which are Schema.org values.
The other 20:

| Record | Country | Value today |
| --- | --- | --- |
| blender | NL | `Stichting` |
| eclipse | BE | `Belgian charitable; Nonprofit501c6` |
| efa | AU | `Incorporated association; ACNC registered charity` |
| ffpc | NL | `algemeen nut beogende instelling` |
| fsfe | DE | `charitable e.V.` |
| gentoo | US (NM) | `New Mexico non profit` |
| joomla | US | `charitable` |
| kde | DE | `DEAssociation` |
| lpi_org | CA | (empty) |
| matrix | UK | `CommunityInterestCompany ` (trailing space) |
| openhomefoundation | CH | `stiftung` |
| opensourceeurope | BE | `ASBL` |
| openssl | US | `Delaware non-profit corporation` |
| openstreetmap | UK | `LimitedByGuaranteeCharity` |
| osgeo | US | `Nonprofit501c4` |
| ow2_org | FR | `French 1901 Non-profit Association` |
| raspberrypi | UK | `LimitedByGuaranteeCharity` |
| stewardshiplab | UK | `LimitedByGuaranteeCharity`, with a comment that charity registration is in progress |
| structuredworld | RO | `""` |
| tdf | DE | `charitable` |

`openstreetmap`, `raspberrypi`, `stewardshiplab` and `osgeo` already use Schema.org values.

## What Schema.org covers

[NonprofitType](https://schema.org/NonprofitType) has three subtypes:

- [USNonprofitType](https://schema.org/USNonprofitType): `Nonprofit501a`, `Nonprofit501c1`
  to `Nonprofit501c28`, `Nonprofit501d`, `Nonprofit501e`, `Nonprofit501f`, `Nonprofit501k`,
  `Nonprofit501n`, `Nonprofit501q`, `Nonprofit527`. These are IRS tax statuses.
- [UKNonprofitType](https://schema.org/UKNonprofitType):
  `CharitableIncorporatedOrganization`, `LimitedByGuaranteeCharity`, `UKTrust`,
  `UnincorporatedAssociationCharity`. These are charity legal forms.
- [NLNonprofitType](https://schema.org/NLNonprofitType): `NonprofitANBI`,
  `NonprofitSBBI`. These are Dutch tax statuses.

Nothing covers Germany, Switzerland, Belgium, France, Australia, Canada, Romania, US
state-only nonprofits, or UK community interest companies. So an enum needs some values
of our own for the 12 records outside Schema.org.

## Proposal (open question 1)

- Use a Schema.org value wherever one fits.
- Otherwise use our own value, named for the ISO 3166 country code and the local legal
  form or status, in the same CamelCase style. `kde` already does this with `DEAssociation`.
  Each value is defined in the schema with `oneOf` `const` and `description`, as the
  crosswalk evidence types are (PR #107). Each description links the law or register
  that defines the form. The values become `ffi:` terms when the foundations dataset
  moves to v2.
- Keep `; ` between values when a foundation holds two statuses, as `eclipse` does
  today. The US-dollar check already splits on `;`. In JSON Schema, the field becomes a
  string whose `pattern` allows one or more enum values joined by `; `. A test checks that
  every value is defined.
- The categories page groups the third column by country, using the value's prefix or
  Schema.org subtype.

## Proposed value for each record

**Mechanical**: the new value only restates what the record already says. These need
no new source.

| Record | Proposed value | Why |
| --- | --- | --- |
| ffpc | `NonprofitANBI` | "algemeen nut beogende instelling" is ANBI written out |
| matrix | `UKCommunityInterestCompany` | the same value without the trailing space, with a country prefix since Schema.org has no CIC |
| kde | `DEeV` | "DEAssociation" for an e.V. (`legalName` KDE e.V.); renamed so that every German association uses the same value. Or keep `DEAssociation` |
| opensourceeurope | `BEASBL` | "ASBL", in Belgium |
| ow2_org | `FRAssociation1901` | "French 1901 Non-profit Association" |
| openhomefoundation | `CHStiftung` | "stiftung", in Switzerland |
| gentoo | `USStateNonprofit` | "New Mexico non profit"; `addressRegion` already gives the state |
| openssl | `USStateNonprofit` | "Delaware non-profit corporation"; but its `addressRegion` is `DE`, which is Germany's country code, not Delaware's state code, so that field needs a look too |
| efa | `AUIncorporatedAssociation; AUACNCCharity` | both parts are already stated |
| structuredworld | `ROAsociatie` | the `legalName` is "Asociația …"; the value today is empty |

**Needs a source.** The value today is too vague to map without checking the
organization's own site, which the data rules require:

| Record | Value today | What to check |
| --- | --- | --- |
| blender | `Stichting` | whether Blender Foundation has ANBI status (`NonprofitANBI`), or is only a stichting (`NLStichting`) |
| eclipse | `Belgian charitable; Nonprofit501c6` | the Belgian legal form of Eclipse Foundation AISBL (probably `BEAISBL; Nonprofit501c6`) |
| fsfe | `charitable e.V.` | `DEeV`, and whether to record German charitable (gemeinnützig) status as a second value, `DEGemeinnuetzig` |
| tdf | `charitable` | The Document Foundation's German legal form (a Stiftung) and status: `DEStiftung`, perhaps with `DEGemeinnuetzig` |
| joomla | `charitable` | Open Source Matters, Inc.'s IRS status, probably `Nonprofit501c3` |
| lpi_org | (empty) | the Canadian legal form and status of Linux Professional Institute |

## Open questions

1. **Values outside Schema.org.** Use our own values named for the country code and the
   local form or status (`DEeV`, `CHStiftung`, `BEASBL`), or another scheme?
2. **Legal form or tax status.** Schema.org mixes the two: US and NL values are tax
   statuses, UK values are legal forms. Record both where both exist, as `efa` would
   (`AUIncorporatedAssociation; AUACNCCharity`), or one per foundation?
3. **Empty values.** `nonprofitStatus` is required. Until its source is checked, should
   `lpi_org` keep an empty value, or should there be an `Unknown` value?

## Decisions

1. **Values outside Schema.org** (Shane Curcuru, 2026-11-15, choosing "Country code plus
   local form"): use Schema.org values where one fits, otherwise our own values named for
   the ISO 3166 country code and the local legal form or status, each defined in the
   schema.

Questions 2 and 3 were not answered separately. PR #110 follows the proposal: where a
source states both a legal form and a status, record both (`efa`, `tdf`). Empty values
mean "unknown", since fdncheck's validator skips blank fields; after the checks below,
no record is empty.

## Result

The schema lists every value in `definitions/nonprofitType` (all Schema.org
`NonprofitType` members, plus 14 of our own). `nonprofitStatus` has a `pattern` built
from that list, and `x-values` points to it. fdncheck's
`tests/test_nonprofit_types.py` checks that the pattern matches the list and that every
record validates. The table on [the foundation model page](../_pages/fdnmodel.md) is
read from the same list.

These are the six records that needed a source. Each was checked on the organization's
own site on 2026-11-15:

| Record | Value | Source and what it shows |
| --- | --- | --- |
| blender | `NLStichting` | <https://www.blender.org/about/foundation/>: "Stichting Blender Foundation", with a Chamber of Commerce number; no page mentions ANBI |
| eclipse | `BEAISBL; Nonprofit501c6` | <https://www.eclipse.org/org/>: "Eclipse Foundation AISBL", "an international non-profit association". The site does not mention the US entity's 501(c)(6), which is kept from the existing record and still unverified |
| fsfe | `DEeV` | <https://fsfe.org/about/legal/imprint.html>: "Free Software Foundation Europe e.V.", Vereinsregister VR 17030. Charitable status is not stated, so it is left out |
| tdf | `DEStiftung; DEGemeinnuetzig` | <https://www.libreoffice.org/imprint/> (where TDF's imprint redirects): "gemeinnützige rechtsfähige Stiftung des bürgerlichen Rechts" |
| joomla | `USStateNonprofit` | <https://www.opensourcematters.org/organisation/finances/financial-filings.html>: "registered as a Not for Profit Corporation to the NYS Charities Bureau"; no IRS status is stated |
| lpi_org | `CANonprofit` | <https://www.lpi.org/impressum/>: "Linux Professional Institute Inc.", Saint John, NB, "a non profit organization"; no charity registration is stated |

## Future tasks

- The categories page could group its "Non-US Nonprofits" column by country prefix.
- `nonprofit` in `_sponsorships/` is a separate field with its own values (`kde.md` still
  says `DEAssociation`); decide whether it should use the same list.
- `openssl` has `addressRegion: DE`, Germany's country code, not Delaware's state code.
- Foundations whose only status is `USStateNonprofit` don't show amounts in US dollars,
  because the dollar check matches only IRS types. This is the same as before the cleanup.

