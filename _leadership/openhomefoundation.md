---
identifier: openhomefoundation
commonName: Open Home Foundation
asOf: 2026-07-25
sources:
- url: https://www.openhomefoundation.org/structure/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Paulus Schoutsen
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 1.0
- name: Pascal Vizeli
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Member
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 1.0
- name: J. Nick Koston
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 1.0
- name: Trevor Schirmer
  personId: null
  roles:
  - role: Rotating Board Member (commercial partner)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 1.0
- name: Franck Nijhof
  personId: null
  roles:
  - role: Lead of Home Assistant
    roleClass: paid_staff
  - role: Chair of Leadership Committee
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 0.9
- name: Guy Sie
  personId: null
  roles:
  - role: Lead of Marketing
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 0.9
- name: Jean-Loïc Pouffier
  personId: null
  roles:
  - role: Lead of Product & UX
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 0.9
- name: Marcel van der Veldt
  personId: null
  roles:
  - role: Lead of Ecosystem
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 0.9
- name: Melissa Thermidor
  personId: null
  roles:
  - role: Lead of Community
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 0.9
- name: Jose Martin-Corral
  personId: null
  roles:
  - role: Chair of Back Office
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.openhomefoundation.org/structure/
  derived: org_live
  confidence: 0.9
---

# Open Home Foundation — Leadership

The Open Home Foundation is a tax-exempt non-profit Stiftung ("foundation") based in Switzerland (register no. CHE-416.988.952), owning and governing 250+ open source smart-home projects (Home Assistant, ESPHome, Music Assistant, and others). It is funded by commercial partner fees (Nabu Casa, Apollo Automation) and donations, and states it supports more than 50 full-time employees.

Scope: this record captures the two governance tiers published on the /structure/ page.

Board members (4): Paulus Schoutsen (President), Pascal Vizeli (Treasurer), J. Nick Koston (Member), and Trevor Schirmer (Rotating member, commercial partner). President and Treasurer are captured as officers as well as board directors. Trevor Schirmer's seat is explicitly a rotating commercial-partner seat.

Leadership (6): the functional/executive leadership team listed under the "Leadership" heading: Franck Nijhof (Lead of Home Assistant; Chair of Leadership Committee), Guy Sie (Lead of Marketing), Jean-Loïc Pouffier (Lead of Product & UX), Marcel van der Veldt (Lead of Ecosystem), Melissa Thermidor (Lead of Community), and Jose Martin-Corral (Chair of Back Office).

Paid vs volunteer: the four board members are governance and their pay status is not stated (captured as `board_director`, `confidence: 1.0` for the names/roles as listed). The six Leadership individuals are the foundation's operational department leads; since the org states it employs 50+ full-time staff and these are functional management roles, they are tagged `paid_staff` at `confidence: 0.9` (employment not stated verbatim per person). Franck Nijhof also holds the officer role Chair of the Leadership Committee.

Not published (hence `null`): per-person contact (only a generic foundation contact email is given), bios, and term dates. An organigram is linked as a Google Drive document but not parsed here.
