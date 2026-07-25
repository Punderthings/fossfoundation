---
identifier: creativecommons
commonName: Creative Commons
asOf: 2026-07-25
sources:
- url: https://creativecommons.org/governance
  type: org_live
  retrieved: 2026-07-25
people:
- name: Angela Oduor Lungati
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
  sourceUrl: https://creativecommons.org/person/angela-oduorgmail-com/
  derived: org_live
  confidence: 1.0
- name: Glenn O Brown
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
  sourceUrl: https://creativecommons.org/person/gotisbrowngmail-com/
  derived: org_live
  confidence: 1.0
- name: Marta Belcher
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Audit Committee Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/martabelchergmail-com/
  derived: org_live
  confidence: 1.0
- name: Anna Tumadóttir
  personId: null
  roles:
  - role: CEO
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/annacreativecommons-org/
  derived: org_live
  confidence: 1.0
- name: Sarah Hinchliff Pearson
  personId: null
  roles:
  - role: General Counsel
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/sarahcreativecommons-org/
  derived: org_live
  confidence: 1.0
- name: Alwaleed Alkhaja
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/alwaleed-alkhaja/
  derived: org_live
  confidence: 1.0
- name: James Grimmelmann
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/jamesgrimmelmann-net/
  derived: org_live
  confidence: 1.0
- name: Melissa Hagemann
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/melissa-hagemann/
  derived: org_live
  confidence: 1.0
- name: Melissa Omino
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/melissa-omino/
  derived: org_live
  confidence: 1.0
- name: Colin Sullivan
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/colin-sullivan/
  derived: org_live
  confidence: 1.0
- name: Jeni Tennison
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/jenijenitennison-com/
  derived: org_live
  confidence: 1.0
- name: Luis Villa
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://creativecommons.org/person/luislu-is/
  derived: org_live
  confidence: 1.0
---

# Creative Commons — Leadership

Scope: the Board of Directors (12 members) as listed under the "Board" heading on `/governance`, with officer roles captured where the page states them (Board Chair, Vice Chair, Treasurer / Audit Committee Chair, CEO, General Counsel). Anna Tumadóttir (CEO) and Sarah Hinchliff Pearson (General Counsel) are CC executives who also appear under the Board heading; both their executive/officer role and board membership are recorded.

Deliberately excluded (noted for completeness, not current voting governance):
- **Emeritus**: Lawrence Lessig, "Founder / Board Member Emeritus" — honorary, not a current board seat.
- **Advisory Council**: ~28 advisors (e.g. Hal Abelson, Jimmy Wales, Esther Wojcicki [Vice Chair of the Advisory Council], Ryan Merkley, Molly Van Houweling). Advisory body, not governance.
- **Staff**: CC publishes a separate staff roster at https://creativecommons.org/team (paid employees). Not captured in this governance-focused record; available for a staff-dataset pass. The CEO and General Counsel are the only executives who also hold board seats and are included above.

Paid vs volunteer: the board page does not state pay status for directors; treated as volunteer directors. The CEO and General Counsel are CC employees (paid), reflected by their executive titles.

Contact: no per-person contact is published on the governance page. The individual `/person/<slug>` URLs are used as `source_url` but several slugs are email-derived artifacts (e.g. "...gmail-com"); these are NOT treated as published contact and `contact` is left null for all to avoid fabricating addresses.

Bios: each director links to a `/person/<slug>` profile page with a full bio, but the governance listing shows only truncated teasers. To avoid storing partial/misleading text, `bio` is left null here; a bio-enrichment pass can fetch the 12 profile pages and capture them verbatim.

Term dates: none published on the governance page (null for all).
