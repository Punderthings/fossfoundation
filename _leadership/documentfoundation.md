---
identifier: documentfoundation
commonName: The Document Foundation
asOf: 2026-07-25
sources:
- url: https://www.documentfoundation.org/governance/board/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Eliane Domingos
  personId: null
  roles:
  - role: Chairperson
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Eliane is a businesswoman, coworking business consultant, consultant and instructor in LibreOffice
    migration. Member of TDF for 11 years, member of the Brazilian LibreOffice community promoting LibreOffice
    at events and on social networks. Participated in the LibreOffice Magazine project for 27 editions.
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
- name: Simon Phipps
  personId: null
  roles:
  - role: Deputy Chairperson
    roleClass: officer
  - role: Deputy Board Member
    roleClass: board_director
  contact: null
  bio: Simon has been involved with what is now LibreOffice since participating in the launch of OpenOffice
    in 2000 just after joining Sun Microsystems. He helped start the Open Document Format standard at
    OASIS, worked alongside and ultimately hosted the StarOffice team at Sun, liaised with and supported
    the founders of LibreOffice until Sun closed, joined TDF from the beginning and ran the first Board
    elections for the Membership Committee, served on the Board twice, facilitated renewed crowdfunding
    of ODF standardisation in TDF's COSM project, and ensured the needs of The Document Foundation are
    understood by the European Commission in connection with legislation such as the Cyber Resilience
    Act. Simon founded Meshed Insights Ltd where his main client is the Open Source Initiative.
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
- name: Sophie Gautier
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  - role: Foundation Coordinator (contracted)
    roleClass: paid_staff
  contact: null
  bio: Sophie is part of the LibreOffice project since its creation and contributes to the French localization.
    She runs her own company (SapienceTic) and is currently contracted as foundation coordinator for the
    foundation.
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
- name: László Németh
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: László is a free software activist and contributor since 2002 (Csevej Bt., Hungary).
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
- name: Osvaldo Gervasi
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Osvaldo was a member of the Board of Directors also in the period 2016-2020. He served TDF and
    LibreOffice in migration activities (inspiring the LibreUmbria Project as President of Umbria's Open
    Source Competence Center, participating in the migration of the Italian Army, Air and Navy), and delivering
    talks in schools. He is a member of the Italian Localization Team. He is an Associate Professor and
    Deputy Director of the Department of Mathematics and Computer Science of Perugia University (since
    November 2019), President since 2023 of the professional degree course L-P03, Project Leader of the
    LibreEOL platform, and President and co-founder of the non-profit organization ICCSA since 2013. He
    is a Senior Member of IEEE and ACM since 2009.
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
- name: Paolo Vecchi
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Paolo is based in Luxembourg and works for his organisation, Omnis Cloud Sarl, which specialises
    in the promotion of Open Source based private and hybrid platforms for private and public sector institutions
    to show that achieving Digital Sovereignty is possible. His company has provided free services to
    schools and non-profit organisations and free hosting of LibreOffice videos on its PeerTube instance.
    He has contributed to the LibreOffice project during the last and current board terms, including publishing
    LibreOffice in app stores.
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
- name: Mike Saunders
  personId: null
  roles:
  - role: Deputy Board Member
    roleClass: board_director
  contact: null
  bio: Mike is a long-time advocate of free and open source software, working as a journalist in the FOSS
    world since 1998. He wrote for Linux Format and Linux Voice magazines, and has written books about
    Linux and programming. He joined The Document Foundation in 2016, working in marketing and community
    outreach, and joined the Board of Directors as a Deputy in 2024.
  termStart: null
  termEnd: null
  sourceUrl: https://www.documentfoundation.org/governance/board/
  derived: org_live
  confidence: 1.0
---

# The Document Foundation — Leadership

Scope: the TDF Board of Directors (`/governance/board/`). TDF is the German (Berlin) non-profit ("Stiftung") behind LibreOffice. The board is directly elected by Community Members. Per the site the Board consists of seven (7) members and three (3) deputies.

Individuals captured from the live board page (7): Eliane Domingos (Chairperson), Simon Phipps (Deputy Chairperson), Sophie Gautier, László Németh, Osvaldo Gervasi, Paolo Vecchi, and Mike Saunders (Deputy, joined board as Deputy in 2024).

GAP / possible incompleteness: the stated composition is 7 full members + 3 deputies (10 total), but the fetched page rendered only 7 named individuals (two of them — Simon Phipps and Mike Saunders — explicitly marked "Deputy"). The full-member vs deputy split and any additional deputies could not be fully resolved from the rendered page; treat the roster as likely incomplete and retry against `/governance/board/` (and cross-check `/governance/mc/` for the Membership Committee, which is a separate elected body and is deliberately excluded here). Deputies are recorded with `role_class: board_director` and a "Deputy" role label.

Paid vs volunteer: board directors are elected community volunteers. One exception: Sophie Gautier is "currently contracted as foundation coordinator for the foundation" — explicitly a contracted/paid role — so she carries both `board_director` and `paid_staff` (Foundation Coordinator). Mike Saunders works for TDF in marketing/community outreach (joined 2016); his employment status on the board page is not explicit beyond the narrative, so only his board role is recorded.

Term dates: not recorded. The site's narrative mentions join years (e.g. Mike Saunders "joined the Board as a Deputy in 2024", Osvaldo Gervasi served "2016-2020"), but per the crawl rules these prose join-years are NOT used as `term_start`/`term_end` (left `null`). Historical board terms are published separately (board-2012-2014 … board-2022-2024) and are the source for the leadership-history dataset. Bios: published verbatim (captured). Contact: not published per person (`null`).
