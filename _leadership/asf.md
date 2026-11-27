---
identifier: asf
commonName: The Apache Software Foundation
asOf: 2026-07-24
sources:
- url: https://www.apache.org/foundation/board/
  type: org_live
  retrieved: 2026-07-24
people:
- name: Sander Striker
  personId: null
  roles:
  - role: Board Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Justin Mclean
  personId: null
  roles:
  - role: Vice Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Zili Chen
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Shane Curcuru
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Christofer Dutz
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Emmanuel Lécharny
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Jean-Baptiste Onofré
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Christopher Schultz
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Greg Stein
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Ruth Suehle
  personId: null
  roles:
  - role: President
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Daniel Ruggeri
  personId: null
  roles:
  - role: Executive Vice President
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Craig McClanahan
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Matt Sicker
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Craig L Russell
  personId: null
  roles:
  - role: Assistant Secretary
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Roman Shaposhnik
  personId: null
  roles:
  - role: V.P., Legal Affairs
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Mark J. Cox
  personId: null
  roles:
  - role: V.P., Security
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Andy Seaborne
  personId: null
  roles:
  - role: V.P., W3C Relations
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: org_live
  confidence: 1.0
- name: Chris Lambertus
  personId: null
  roles:
  - role: Infrastructure Administrator
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.apache.org/foundation/board/
  derived: synthesized
  confidence: 0.5
---

# The Apache Software Foundation — Leadership

Scope of this record: the ASF Board of Directors (9 members) and the Foundation Officers / Corporate Officers listed on the leadership page. The ~200+ project VPs (PMC chairs) are project-level roles, not foundation leadership, and are deliberately excluded here (they are available on the same page and could be captured as a separate project-roles dataset if wanted).

Paid vs volunteer: the ASF states its leadership is "composed entirely of volunteers". No board director or officer is paid. The only plausibly paid/contracted role is the Infrastructure Administrator (Chris Lambertus); the site does not state employment status, so it is tagged `paid_staff` with `confidence: 0.5` pending confirmation. Treat as unverified.

Not published on this page (hence `null`): contact info, bios, and term dates for all individuals. ASF board term history is maintained separately as a timeline at https://www.apache.org/history/directors.html and via Whimsy, which is where the leadership-history dataset for ASF should draw from.

Additional corporate officers listed but not yet captured as individual records here (all `officer` class, all `confidence: 1.0`, same source): V.P. Brand Management (Mark Thomas), Conferences (Brian Proffitt), Data Privacy (Christian Grobmeier), Diversity and Inclusion (Daniel Gruno), ECMA Relations (Piotr Karwasz), Fundraising (Bob Paulin), Sponsor Relations (Sally Khudairi), Infrastructure (Danny Angus), Marketing and Publicity (Brian Proffitt), Tooling (Dave Fisher), Travel Assistance (Gavin McDonald), Public Affairs (Dirk-Willem van Gulik).
