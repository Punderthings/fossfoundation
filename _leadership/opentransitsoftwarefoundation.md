---
identifier: opentransitsoftwarefoundation
commonName: Open Transit Software Foundation
asOf: 2026-07-25
sources:
- url: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  type: org_live
  retrieved: 2026-07-25
people:
- name: Kari Watkins
  personId: null
  roles:
  - role: Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'University constituency: UC Davis.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Alan Borning
  personId: null
  roles:
  - role: Vice Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'University constituency: University of Washington.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Devin Braun
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'Transit agency constituency: San Diego Metropolitan Transit System, California.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Will Wong
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'Transit agency constituency: Metropolitan Transportation Authority, New York City.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Pete Dussin
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'Transit agency constituency: Sound Transit, Washington State.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Lauren Main
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'Transit agency constituency: King County Metro, Washington State.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Joshua Kavanagh
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'University constituency: University of California at San Diego.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Jan-Dirk Schmöcker
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'University constituency: Kyoto University.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Matt Caywood
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'Companies and non-profits constituency: Actionfigure.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Wojciech Kulesza
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: 'Companies and non-profits constituency: goEuropa.'
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Sean Óg Crudden
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Individual developers and activists constituency.
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 1.0
- name: Aaron Brethorst
  personId: null
  roles:
  - role: Executive Director
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://opentransitsoftwarefoundation.org/overview/board-of-directors
  derived: org_live
  confidence: 0.6
---

# Open Transit Software Foundation (OTSF) — Leadership

Scope of this record: the OTSF Executive Director and Board of Directors, captured from the live "Board of Directors" page. OTSF is a 501(c)(3) non-profit formed to provide governance for the OneBusAway project.

Board structure: the board is composed of up to 12 members drawn from four constituencies — transit agencies using OneBusAway (2-4 seats), universities doing OneBusAway research (2-4), companies and non-profits involved in OneBusAway (2-4), and independent developers and activists (2-4). Eleven directors currently serve. Each person's constituency is recorded in the `bio` field, since the page publishes affiliation rather than a personal bio.

Officers: the page lists Chair (Kari Watkins), Vice Chair (Alan Borning), Secretary (Devin Braun), and Treasurer (Will Wong); each is a sitting director, so their board seat and officer role are merged into one record.

Paid vs volunteer: Aaron Brethorst is listed as Executive Director, above the board. The page does not state whether the ED post is paid, so it is captured `paid_staff` at confidence 0.6 — the title implies an operational (likely employed) role, but employment status is not verified. Board directors are captured `board_director` at confidence 1.0; the page does not state volunteer status, though board service at a small 501(c)(3) is typically unpaid.

Not published (hence `null`): per-person contact, bios (only constituency/affiliation is given, recorded in `bio`), and term dates. The page states board members "are elected each year at the annual meeting" but gives no specific term dates.
