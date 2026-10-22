---
identifier: gnome
commonName: GNOME Foundation
asOf: 2026-07-24
sources:
- url: https://foundation.gnome.org/team
  type: org_live
  retrieved: 2026-07-24
- url: https://foundation.gnome.org/
  type: org_live
  retrieved: 2026-07-24
people:
- name: Allan Day
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Executive Director (acting)
    roleClass: paid_staff
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Allan is the current President of the GNOME Foundation, and is serving in the Executive Director
    role. He is responsible for the day-to-day running of the organization, and works closely with the
    staff team, officers, and the Executive Committee. Prior to taking the President role, Allan had over
    seven years experience as a member of the GNOME Foundation Board of Directors, including time spent
    as the Board Chair. Outside of the Foundation, he has participated in many different aspects of the
    GNOME project, including design, documentation, and marketing.
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Kristi Progri
  personId: null
  roles:
  - role: Director of Program Management
    roleClass: paid_staff
  contact: null
  bio: As the Director of Program Management, Kristi oversees the GNOME Pathways Initiative to recruit,
    mentor, and elevate new creators from diverse regions. She manages Pathways goals aligned with the
    strategic plan, promoting diversity, equity, and inclusion and she executes all Foundation conferences
    and events.
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Bartłomiej Piotrowski
  personId: null
  roles:
  - role: Infrastructure Engineer
    roleClass: paid_staff
  contact: null
  bio: As the Infrastructure Engineer, Bartłomiej plans, manages, and delivers services that ensure the
    Foundations's technical platforms are reliable, efficient, and well-maintained. He is responsible
    for managing all infrastructure hosting the organization's websites and auxiliary services, and maintaining
    Flathub.
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Anonymous
  personId: null
  roles:
  - role: Administrative Assistant
    roleClass: paid_staff
  contact: null
  bio: The GNOME Foundation's Administrative Assistant is responsible for a wide variety of clerical tasks.
    This staff member supports bookkeeping efforts through invoicing, reconciling expense reports, and
    preparing materials for tax filing and she assists with scheduling and meeting coordination, managing
    donor and general mailing lists, and responding to inquiries from the community.
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Robert McQueen
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Cassidy James Blaede
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Maria Majadas
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Federico Mena Quintero
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Arun Raghavan
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Julian Sparber
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Lorenz Wildberg
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
- name: Deepa Venkatraman
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://foundation.gnome.org/team
  derived: org_live
  confidence: 1.0
---

# GNOME Foundation — Leadership

Scope of this record: the GNOME Foundation staff team (paid) and the Board of Directors, as published on the org's live Team page (https://foundation.gnome.org/team). The GNOME Foundation is a membership-based organization with a board elected annually by its members.

Paid vs volunteer: the Team page explicitly groups four people under "The GNOME Foundation staff team" — Allan Day, Kristi Progri, Bartłomiej Piotrowski, and the (unnamed) Administrative Assistant. That explicit "staff team" grouping is the org's own labelling, so all four are tagged `paid_staff` with `confidence: 1.0`. This is a stronger signal than ASF's, where employment status was not stated. The nine Board of Directors members are elected volunteers (the governing board) and are tagged `board_director`.

Allan Day dual/triple role: he is listed both under the staff team and on the Board. The page states he is the current President, "is serving in the Executive Director role" (day-to-day running), and previously spent over seven years on the Board including time as Board Chair. He is therefore recorded with three roles: President (`officer`), Executive Director (acting) (`paid_staff`), and Board Director (`board_director`). All three role facts are stated verbatim, so `confidence: 1.0`; the "(acting)" qualifier on ED reflects the page's "serving in the Executive Director role" wording rather than a permanent ED appointment.

Administrative Assistant name: the org deliberately publishes this staff member as "Anonymous" (no name given). The name field records "Anonymous" verbatim as published; it is NOT a missing/unknown value and has not been fabricated. Bio and role are published; the individual's name is withheld by the org.

Officers: the only officer named on this page is the President (Allan Day). GNOME's board elects officers (e.g. Chair, Treasurer, Secretary), but no other officer holders are published on the Team page, so none are recorded here (not fabricated). Officer detail, if needed, would come from the Foundation Handbook (https://handbook.gnome.org/foundation/board-of-directors.html) or annual reports.

Not published on this page (hence `null`): contact info and term dates (term_start/term_end) for all individuals; bios for all nine board directors. Bios are published only for the four staff members and are captured verbatim. The board is stated to be "elected annually" but no per-person term dates are given.

People captured: 12 distinct individuals (4 staff — one of whom, Allan Day, is also President and a Board Director — plus 8 further Board Directors, for 9 board members total).
