---
identifier: bytecodealliance
commonName: Bytecode Alliance Foundation
asOf: 2026-07-25
sources:
- url: https://bytecodealliance.org/about
  type: org_live
  retrieved: 2026-07-25
people:
- name: Bobby Holley
  personId: null
  roles:
  - role: Board Chair
    roleClass: officer
  - role: Member Director (Mozilla)
    roleClass: board_director
  contact: github:bholley
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Bailey Hayes
  personId: null
  roles:
  - role: At-Large Director
    roleClass: board_director
  - role: TSC Elected Delegate
    roleClass: volunteer
  contact: github:ricochet
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Pat Hickey
  personId: null
  roles:
  - role: At-Large Director
    roleClass: board_director
  contact: github:pchickey
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Tyler McMullen
  personId: null
  roles:
  - role: Member Director (Fastly)
    roleClass: board_director
  contact: github:tyler
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Till Schneidereit
  personId: null
  roles:
  - role: TSC Director
    roleClass: board_director
  - role: TSC Appointed Delegate
    roleClass: volunteer
  contact: github:tschneidereit
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Oscar Spencer
  personId: null
  roles:
  - role: Member Director (F5)
    roleClass: board_director
  - role: TSC Chair
    roleClass: volunteer
  contact: github:ospencer
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Ralph Squillace
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Member Director (Microsoft)
    roleClass: board_director
  contact: github:squillace
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: Deian Stefan
  personId: null
  roles:
  - role: Member Director (UCSD)
    roleClass: board_director
  contact: github:deian
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
- name: David Bryant
  personId: null
  roles:
  - role: Consulting Executive Director
    roleClass: paid_staff
  contact: github:disquisitioner
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 0.9
- name: Christof Petig
  personId: null
  roles:
  - role: TSC Elected Delegate
    roleClass: volunteer
  contact: github:cpetig
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://bytecodealliance.org/about
  derived: org_live
  confidence: 1.0
---

# Bytecode Alliance Foundation — Leadership

Scope: the Board of Directors (top-level oversight body) and the Technical Steering Committee (TSC), both captured from the single /about page. The TSC is the top-level governing body for hosted projects and SIGs; TSC Directors sit on the Board, so it is treated here as foundation governance rather than a purely project-level committee. Recognized Contributors (an individual-contributor program) are not captured.

Board composition (9 seats): Member Directors elected by member organizations (Mozilla, Fastly, F5, Microsoft, UCSD named on the page), At-Large Directors, and a TSC Director. Officers named: Board Chair (Bobby Holley), Treasurer (Ralph Squillace). The Consulting Executive Director (David Bryant) "supports the Board and oversees day-to-day operations as well as member relations" — tagged `paid_staff` at confidence 0.9 because the "Consulting Executive Director" title and operational remit imply a paid/contracted role, though employment status is not stated verbatim.

TSC delegates captured: Bailey Hayes (Elected), Till Schneidereit (Appointed, TSC Director), Oscar Spencer (Elected, TSC Chair), Christof Petig (Elected). The first three also hold Board seats and are recorded once with both roles; Christof Petig is TSC-only and recorded as a `volunteer`.

Contact: the org publishes a GitHub handle per person (captured in `contact` as `github:<handle>`); no email or other contact is published.

Term dates: the page states Directors serve "a two-year term, staggered across elections every December". This is a general policy, not a per-person stated term, so `term_start`/`term_end` are left null per the no-inference rule.

Not published (hence null): bios, per-person email, and explicit term dates for all individuals.
