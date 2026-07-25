---
identifier: tug
commonName: TeX Users Group
asOf: 2026-07-25
sources:
- url: https://tug.org/board.html
  type: org_live
  retrieved: 2026-07-25
people:
- name: Arthur Rosendahl
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Erik Nijenhuis
  personId: null
  roles:
  - role: Vice President
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Jim Hefferon
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Karl Berry
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Barbara Beeton
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Boris Veytsman
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Doris Behrendt
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Johannes Braams
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Max Chernoff
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Kaja Christiansen
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Ulrike Fischer
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Tom Hejda
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Klaus Höppner
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Jérémy Just
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Frank Mittelbach
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2029'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Norbert Preining
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: '2027'
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 1.0
- name: Sophia Laakso
  personId: null
  roles:
  - role: Office Administrator
    roleClass: paid_staff
  contact: null
  bio: null
  termStart: '2023'
  termEnd: null
  sourceUrl: https://tug.org/board.html
  derived: org_live
  confidence: 0.9
---

# TeX Users Group — Leadership

Scope: the TUG Board of Directors (15 Director positions plus the President, per the TUG bylaws; the board is currently at capacity with 16 members) and the paid office administrator. TUG is a US 501(c) membership organisation whose directors are elected by the membership.

Term dates: the board page states "the year in parentheses is when that member's term expires", so `term_end` is captured verbatim as the stated expiry year (all confidence 1.0). `term_start` is not stated on this page and is left null; a full per-person service history (start years, prior offices) exists in the roster section of the same page and could feed the leadership-history dataset.

Officers: the four elected officers are President (Arthur Rosendahl), Vice President (Erik Nijenhuis), Secretary (Jim Hefferon) and Treasurer (Karl Berry); each is also a board director. The executive committee additionally includes Barbara Beeton and Boris Veytsman as members, plus the office administrator (non-voting); these two are recorded here only as board directors since "executive committee member" is a committee assignment rather than a distinct office.

Paid vs volunteer: TUG directors and officers are volunteers. The one paid/contracted role is the office administrator. The current holder, Sophia Laakso (Office Manager, 2023–, per the roster on the same page), is tagged `paid_staff` with `confidence: 0.9`: the role and start year are stated verbatim, but the page does not explicitly state employment/compensation status, so the paid classification is inferred from the "Office Manager" role.

Not published on this page (hence null): per-person contact (the board is reachable only as a group at board@tug.org), bios, and term start dates.
