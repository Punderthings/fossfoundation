---
identifier: wordpress
commonName: WordPress Foundation
asOf: 2026-07-25
sources:
- url: https://wordpressfoundation.org/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Matt Mullenweg
  personId: null
  roles:
  - role: Founder
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://wordpressfoundation.org/
  derived: org_live
  confidence: 0.5
---

# WordPress Foundation — Leadership

Scope and finding: the WordPress Foundation's own site (wordpressfoundation.org, the target site https://wordpress.org/ being the software project, not the charity) publishes NO board, officer, or staff roster. The site menu covers Financial Information, Donate, News, Philosophy, Projects, scholarships, Trademarks, and Contact, with no board/leadership/team/people page.

The only governance-relevant person named anywhere on the site is Matt Mullenweg, described on the About page verbatim as the founder: "a charitable organization founded by Matt Mullenweg". That single fact is captured at confidence 1.0, but "Founder" is a historical designation rather than a current governance office. `role_class` is recorded as `officer` only as a low-confidence best-fit (`confidence: 0.5`) because the site does not state whether Mullenweg currently holds a board seat or officer title. No board membership is asserted.

The WordPress Foundation is a US 501(c)(3); its directors and officers are filed with the IRS (Form 990) and California, but are not published on the foundation website. Those filings — linked under the site's Financials section — are the correct source for a verified board roster and would be the basis for a leadership-history entry.

Not published (hence null / absent): board directors, officers, paid staff, contact, bios, and term dates.

## Fetch attempts
- https://wordpressfoundation.org/ — About/home page; names only the founder, no roster.
