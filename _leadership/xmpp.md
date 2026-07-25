---
identifier: xmpp
commonName: XMPP Standards Foundation
asOf: 2026-07-25
sources:
- url: https://xmpp.org/about/xsf/members/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Ralph Meijer
  personId: null
  roles:
  - role: XSF Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Arne-Bruen Vogelsang
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Florian Schmaus
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Guus der Kinderen
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Mickaël Rémond
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Alexander Gnauck
  personId: null
  roles:
  - role: XSF Secretary
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Peter Saint-Andre
  personId: null
  roles:
  - role: XSF Treasurer
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
- name: Matthew Wild
  personId: null
  roles:
  - role: Executive Director
    roleClass: officer
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://xmpp.org/about/xsf/members/
  derived: org_live
  confidence: 1.0
---

# XMPP Standards Foundation — Leadership

Scope: the XSF Board of Directors and the elected officers (Chair, Secretary, Treasurer, Executive Director). Captured from the current members page (site last built 2026-07-25), which tags each elected member with their Board/Council/officer affiliation.

Board of Directors (tagged "XSF Board"): Ralph Meijer (also XSF Chair), Arne-Bruen Vogelsang, Florian Schmaus, Guus der Kinderen, and Mickaël Rémond. Officers: Ralph Meijer (Chair, and a board director), Alexander Gnauck (Secretary), Peter Saint-Andre (Treasurer), and Matthew Wild (Executive Director). Gnauck, Saint-Andre and Wild are recorded as officers only, since the page does not tag them "XSF Board".

Excluded — technical committee: the XMPP Council is the XSF's elected technical steering body and is deliberately excluded here per the crawl instructions (technical-committee roles are not foundation governance). Its current members, per the same page, are Dan Caseley, Daniel Gultsch, Jérôme Poisson, Marvin Wissfeld, and Stephen Paul Weber. They could be captured as a separate technical-roles dataset if wanted.

Paid vs volunteer: the XSF is a volunteer-run standards body. The Executive Director (Matthew Wild) is the one role that may be compensated, but the page does not state paid/volunteer status, so it is classified `officer` (not `paid_staff`); treat compensation status as unverified.

Not published on this page (hence null): per-person contact, bios, and term dates. The bylaws (https://xmpp.org/about/xsf/bylaws/) and the annual board/council elections are the source for term history and would feed the leadership-history dataset.
