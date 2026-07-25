---
identifier: isc
commonName: Internet Systems Consortium, Inc.
asOf: 2026-07-25
sources:
- url: https://www.isc.org/team/
  type: org_live
  retrieved: 2026-07-25
- url: https://www.isc.org/about/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Jeff Osborn
  personId: null
  roles:
  - role: President
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 1.0
- name: Robert Carolina
  personId: null
  roles:
  - role: General Counsel
    roleClass: paid_staff
  contact: https://linkedin.com/in/robertcarolina
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Darren Ankney
  personId: null
  roles:
  - role: Director of Technical Support
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Ray Bellis
  personId: null
  roles:
  - role: Director of DNS Operations
    roleClass: paid_staff
  contact: https://blop.social/@raybellis
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Jacob D'Erasmo
  personId: null
  roles:
  - role: Director of Accounting and Human Resources
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: T. Marc Jones
  personId: null
  roles:
  - role: Director of Sales
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Michał Kępień
  personId: null
  roles:
  - role: BIND 9 QA Manager, Software Developer
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Tomek Mrugalski
  personId: null
  roles:
  - role: Director of DHCP Engineering
    roleClass: paid_staff
  contact: https://twitter.com/thomsongdn
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Vicky Risk
  personId: null
  roles:
  - role: Director of Marketing
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Ondřej Surý
  personId: null
  roles:
  - role: Director of DNS Engineering
    roleClass: paid_staff
  contact: https://fosstodon.org/@ondrej@sury.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Włodek Wencel
  personId: null
  roles:
  - role: DHCP QA Manager
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 0.9
- name: Rick Adams
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 1.0
- name: Vint Cerf
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 1.0
- name: Stephen Wolff
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.isc.org/team/
  derived: org_live
  confidence: 1.0
---

# Internet Systems Consortium, Inc. — Leadership

Scope of this record: ISC's Board of Directors (3 members), the President, and the Senior Management team, all listed on the /team page under three headings (Staff, Senior Management, Board of Directors). ISC is a not-for-profit 501(c)(3) company incorporated in Delaware (founded 1994; incorporated as Internet Systems Consortium, Inc. in 2004) and employs approximately 45 staff in 15 countries. The ~35 rank-and-file staff (software, QA, support, systems, sales engineers, marketing manager, account managers, system administrators) listed under the "Staff" heading are excluded here as they are not foundation/company leadership; they are captured only at the Senior Management and Board level.

Paid vs volunteer: The Senior Management roster (Directors of various functions, General Counsel) sits within a company that explicitly states it has ~45 paid staff, so these are recorded as `paid_staff` with `confidence: 0.9` — the org does not stamp each person "employee" verbatim, so the paid status is inferred from the Senior Management heading + stated staff count. Jeff Osborn is listed as "President", a corporate officer title stated verbatim, so recorded as `officer` at `confidence: 1.0` (he is also an executive employee). The three Board Members (Rick Adams, Vint Cerf, Stephen Wolff) are recorded as `board_director` at `confidence: 1.0`; the site does not state whether board service is paid or volunteer, so no paid/volunteer determination is made for them.

Contact: Per-person contact is not published as email. Several senior managers have public social handles linked from their tile (Robert Carolina — LinkedIn; Ray Bellis — Mastodon; Tomek Mrugalski — X/Twitter; Ondřej Surý — Mastodon), captured in the `contact` field. Vicky Risk's linked handle resolves to ISC's org account (@iscdotorg) rather than a personal one, so her `contact` is left null.

Not published (hence `null`): bios and term dates for all individuals. ISC does not publish board terms or officer terms on the live site; roster history would need to come from archive.org captures of /team and /board.

URLs used: https://www.isc.org/about/ (confirmed /team link and org history/incorporation status) and https://www.isc.org/team/ (roster). A dedicated /board page exists (linked as /board/#Adams etc.) but was not separately fetched as the /team page already lists all three board members by name under the Board of Directors heading.
