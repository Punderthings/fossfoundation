---
identifier: osmfoundation
commonName: OpenStreetMap Foundation
asOf: 2026-07-25
sources:
- url: https://osmfoundation.org/wiki/Officers_%26_Board
  type: org_live
  retrieved: 2026-07-25
- url: https://osmfoundation.org/wiki/Contractors_and_employees
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
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
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
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
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
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
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
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
  derived: org_live
  confidence: 1.0
- name: Héctor Ochoa Ortiz
  personId: null
  roles:
  - role: Board Member
    roleClass: board_director
  - role: Deputy Secretary
    roleClass: officer
  contact: hector.ochoa.ortiz@osmfoundation.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
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
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
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
  sourceUrl: https://osmfoundation.org/wiki/Officers_%26_Board
  derived: org_live
  confidence: 1.0
- name: Grant Slater
  personId: null
  roles:
  - role: Senior Site Reliability Engineer
    roleClass: paid_staff
  contact: https://github.com/firefishy
  bio: null
  termStart: 2022-05-01
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Contractors_and_employees
  derived: org_live
  confidence: 1.0
- name: Dorothea Kazazi
  personId: null
  roles:
  - role: Administrative Assistant
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: 2016
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Contractors_and_employees
  derived: org_live
  confidence: 0.9
- name: Michelle Heydon
  personId: null
  roles:
  - role: Accountant
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: 2017
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Contractors_and_employees
  derived: org_live
  confidence: 0.9
- name: Martin Raifer
  personId: null
  roles:
  - role: iD Editor Developer (contractor)
    roleClass: paid_staff
  contact: https://github.com/tyrasd
  bio: null
  termStart: 2021-09
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Contractors_and_employees
  derived: org_live
  confidence: 0.9
- name: Minh Nguyễn
  personId: null
  roles:
  - role: OSM Core Software Development Facilitator (contractor)
    roleClass: paid_staff
  contact: https://github.com/1ec5
  bio: null
  termStart: 2025-04
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Contractors_and_employees
  derived: org_live
  confidence: 0.9
- name: Pablo Brasero Moreno
  personId: null
  roles:
  - role: OSM Core Software Engineer (contractor)
    roleClass: paid_staff
  contact: https://github.com/pablobm
  bio: null
  termStart: 2025-09
  termEnd: null
  sourceUrl: https://osmfoundation.org/wiki/Contractors_and_employees
  derived: org_live
  confidence: 0.9
---

# OpenStreetMap Foundation — Leadership

Scope: the OSMF Board of Directors (7 members, elected by OSMF members) with their officer roles, plus long-term paid individuals from the Contractors and employees page. Working group and committee members are volunteer operational roles, not foundation governance, and are excluded (noted below).

Paid vs volunteer: the board page states plainly that "The board members are volunteers." All seven board members serve unpaid; their officer titles (Chairperson, Secretary, Treasurer, Deputy Secretary) are volunteer governance roles. Grant Slater is the one direct employee (Senior Site Reliability Engineer, from 2022-05-01), captured `paid_staff` at confidence 1.0. Dorothea Kazazi (Administrative Assistant, 2016–), Michelle Heydon (Accountant, 2017–) and the ongoing individual contractors Martin Raifer (iD, 2021-09–), Minh Nguyễn (core software facilitator, 2025-04–) and Pablo Brasero Moreno (core software engineer, 2025-09–) are long-term paid individuals, captured `paid_staff` at confidence 0.9 because they are contractors rather than employees.

Contact: the board publishes a per-person `firstname.lastname@osmfoundation.org` alias for every director, so `contact` is populated for all seven from the live page. For paid staff the site links GitHub profiles rather than emails; those handles are recorded in `contact` where published (Kazazi and Heydon have none listed, so `null`).

Term dates: `term_start` for paid individuals reflects the engagement start year/date stated verbatim on the contractors page. No `term_end` is stated for any current individual. Board term dates are not on the board page; per-year membership history lives at https://wiki.openstreetmap.org/wiki/OSMF_board_members_by_year and the leadership-history dataset should draw from there.

Bios: not on the board page; short biographical details are published separately at https://osmfoundation.org/wiki/Board_Member_Bios (not fetched here), so `bio` is null for all.

Excluded (by scope): short-term and past individual contractors (e.g. Mateusz Konieczny, Rubén López Mendoza for specific 2026 projects; and past contractors), recurring facilitation contractors, and all service contracts with companies (Monetum, Buffer.com, banks, DeepL, etc.) listed on the same page. Working Group and Committee liaisons held by board members are captured only as the board role, not as separate governance seats.
