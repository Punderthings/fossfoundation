---
identifier: osmfoundation
commonName: OpenStreetMap Foundation
asOf: 2026-07-25
sources:
- url: https://osmfoundation.org/wiki/Board
  type: org_live
  retrieved: 2026-07-25
people:
- name: Craig Allan
  personId: null
  roles:
  - role: Chairperson
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  contact: craig.allan@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Daniela Waltersdorfer
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  contact: dani.waltersdorfer@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Roland Olbricht
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  contact: roland.olbricht@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Héctor Ochoa Ortiz
  personId: null
  roles:
  - role: Deputy Secretary
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  contact: hector.ochoa.ortiz@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Brazil Singh
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: brazil.singh@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Laura Mugeha
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: laura.mugeha@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Maurizio Napolitano
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: maurizio.napolitano@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 1.0
- name: Dorothea Kazazi
  personId: null
  roles:
  - role: Administrative Assistant
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Board
  derived: org_live
  confidence: 0.7
---

# OpenStreetMap Foundation — Leadership

Scope of this record: the OSMF Board of Directors (7 members) and the officer roles they hold, plus the named Administrative Assistant. Captured from the wiki "Officers & Board" page (last edited 25 September 2025).

Paid vs volunteer: the page states plainly that "The board members are volunteers and are generally elected by the OSMF members." All 7 board members are therefore unpaid governance volunteers, captured `board_director` (with officer roles where held) at confidence 1.0. The three officer posts are Chairperson (Craig Allan), Secretary (Daniela Waltersdorfer), and Treasurer (Roland Olbricht); Héctor Ochoa Ortiz additionally serves as Deputy Secretary.

Contact: OSMF publishes a per-person `@osmfoundation.org` email for each board member, so `contact` is populated at confidence 1.0 for all seven. Dorothea Kazazi is named as the Administrative Assistant to whom the `board@osmfoundation.org` alias is copied; she is captured `paid_staff` at confidence 0.7 — she is linked under the wiki's "Contractors and employees" page (implying paid status) but that page was not fetched and no personal email is published for her.

Not published on this page (hence `null`): bios (a separate "Board Member Bios" page exists) and term dates (a separate "OSMF board members by year" page holds term history and is the correct source for the leadership-history dataset).

Excluded: the many working-group and committee liaison roles each board member holds (e.g. CWG, DWG, LWG liaisons; Finance and Personnel Committee chairs) are operational assignments within board service, not distinct governance offices, so they are noted here but not recorded as separate `roles`.
