---
identifier: blender
commonName: Stichting Blender Foundation
asOf: 2026-07-25
sources:
- url: https://www.blender.org/about/foundation/
  type: org_live
  retrieved: 2026-07-25
- url: https://www.blender.org/about/people/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Francesco Siddi
  personId: null
  roles:
  - role: Board Chairman
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  - role: CEO
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
- name: Fiona Cohen
  personId: null
  roles:
  - role: Board Secretary
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  - role: COO · Producer
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
- name: Dalai Felinto
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  - role: Head of Product
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
- name: Sergey Sharybin
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  - role: Head of Development
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
- name: Ton Roosendaal
  personId: null
  roles:
  - role: Supervisory Board Chairman
    roleClass: board_director
  contact: null
  bio: Founder and former CEO
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
- name: Carel-Jan van Driel
  personId: null
  roles:
  - role: Supervisory Board Member
    roleClass: board_director
  contact: null
  bio: Former Director of Philips Research
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
- name: Anja Vugts-Verstappen
  personId: null
  roles:
  - role: Supervisory Board Member
    roleClass: board_director
  contact: null
  bio: Former Blender Financial Manager
  termStart: null
  termEnd: null
  sourceUrl: https://www.blender.org/about/foundation/
  derived: org_live
  confidence: 1.0
---

# Stichting Blender Foundation — Leadership

Scope of this record: the governance leadership of Stichting Blender Foundation (est. 2002, Amsterdam; Chamber of Commerce 34176425). Two bodies are published in the Contact block of /about/foundation/: the Board and the Supervisory Board.

Board (statutory management board):
- Chairman: Francesco Siddi (also CEO)
- Secretary: Fiona Cohen (also COO / Producer)
- Members: Dalai Felinto (Head of Product), Sergey Sharybin (Head of Development)

These four are also the executive leadership of the Blender Institute (the Foundation's working company). Each is captured with their governance role(s) plus their executive staff title (paid_staff), since /about/people/ lists them among the paid Amsterdam HQ team. Chairman and Secretary are additionally flagged as officer roles.

Supervisory Board (oversight body, established January 2026 per /about/people/): Chairman Ton Roosendaal (Blender founder and former CEO), members Carel-Jan van Driel (former Director of Philips Research) and Anja Vugts-Verstappen (former Blender Financial Manager). Captured as board_director class (a supervisory-board seat); their descriptor lines are captured as bio.

Paid vs volunteer: the four management-board members are paid executives (paid_staff, confidence 1.0). The three supervisory-board members' compensation is not stated; they are recorded as governance (board_director) without a paid_staff claim.

Deliberately EXCLUDED from person records: the full ~65-person Blender Institute "Amsterdam HQ" and "Online Team" rosters on /about/people/ (developers, artists, TDs, bug triagers, office managers, etc.). These are the Foundation's operational workforce rather than its leadership, and are excluded to mirror the ASF worked example's exclusion of non-governance/operational roles. Only the four who also hold a foundation board seat are carried over from that page. If a full paid-staff roster is wanted later, /about/people/ is the source.

Bios: no narrative bios for the management board (nationality only is shown on /about/people/ and is noted here, not treated as bio). The three supervisory-board members have a one-line descriptor, captured verbatim as bio.

Contact: no per-person contact published (null for all). Foundation contact is foundation@blender.org (organizational/branding/legal/press only).

Term dates: none stated per person. The Supervisory Board was formed "since January 2026" (a board-inception note, not a per-person term), so term_start/term_end are left null.

People captured: 7 (4 management board incl. 2 officers, 3 supervisory board).

web_fetch calls: 3 (/about/, /about/foundation/, /about/people/).
