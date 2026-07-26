---
identifier: commonhaus
commonName: Commonhaus Foundation
asOf: 2026-07-25
sources:
- url: https://www.commonhaus.org/about
  type: org_live
  retrieved: 2026-07-25
people:
- name: Erin Schnabel
  personId: null
  roles:
  - role: Councilor
    roleClass: board_director
  - role: Chair
    roleClass: officer
  contact: github:ebullient
  bio: Java Champion. Maker of things. Distinguished Engineer @ Red Hat, Senior Technical Staff Member
    @ IBM
  termStart: 2023
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
- name: Cesar
  personId: null
  roles:
  - role: Councilor
    roleClass: board_director
  - role: Treasurer
    roleClass: officer
  contact: github:cealsair
  bio: Staff Developer Advocate @ GitLab. Former @ Red Hat, IBM, Oracle, BEA Systems, TIBCO, Lucent Technologies,
    AT&T Bell Labs.
  termStart: 2023
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
- name: Ken Finnigan
  personId: null
  roles:
  - role: Councilor
    roleClass: board_director
  - role: Secretary
    roleClass: officer
  contact: github:kenfinnigan
  bio: Open source engineer, observability, @open-telemetry, author, amateur genealogist. Former @ Red
    Hat.
  termStart: 2023
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
- name: Andres Almiray
  personId: null
  roles:
  - role: Social Media
    roleClass: officer
  contact: github:aalmiray
  bio: I code for fun and help others in the process. Java Champion Alumni. Co-founder of Hackergarten
    & Hack.Commit.Push. Creator of @jreleaser
  termStart: null
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
- name: ashni
  personId: null
  roles:
  - role: Advisory Board Committee Chair
    roleClass: officer
  contact: github:ashni-mehta
  bio: product @ github
  termStart: null
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
- name: Rebbecca Bishop
  personId: null
  roles:
  - role: Community Manager
    roleClass: officer
  contact: github:sigrunixia
  bio: Customer Experience Specialist for @obsidianmd and friend of @commonhaus
  termStart: null
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 0.9
- name: Scott M Stark
  personId: null
  roles:
  - role: Eclipse Foundation Liaison
    roleClass: officer
  contact: github:starksm64
  bio: Developer at IBM, JBoss co-founder
  termStart: null
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
- name: Mark Szymanski
  personId: null
  roles:
  - role: Advisory Board Representative (HeroDevs)
    roleClass: volunteer
  contact: github:markszymanski
  bio: Technical Product Manager at HeroDevs
  termStart: null
  termEnd: null
  sourceUrl: https://www.commonhaus.org/about
  derived: org_live
  confidence: 1.0
---

# Commonhaus Foundation — Leadership

Scope: the foundation governance bodies from the /about page — Councilors (the governing council), Officers, and the sponsor-nominated Advisory Board. Project Representatives and general Members are excluded as project-level / non-governance (see below).

Councilors are the top governing body: "Elected by CF Members, they serve as the voice of our community." Three founding councilors are listed, each recorded as `board_director` (Councilor) plus their officer title: Erin Schnabel (Chair), Cesar (Treasurer), Ken Finnigan (Secretary). All three carry "Founder" designation and an explicit "Term start: 2023" (captured in `term_start`; `term_end` is null). The page notes founding councilors will stand for election as their terms expire.

Officers (functional foundation roles): Andres Almiray (Social Media), ashni (Advisory Board Committee Chair), Rebbecca Bishop (Community Manager), Scott M Stark (Eclipse Foundation Liaison). All are recorded as `officer` at confidence 1.0 except Rebbecca Bishop (Community Manager) at 0.9 — the "Officers" heading places her here, but the operational title leaves paid-vs-volunteer status ambiguous and no employment status is stated.

Advisory Board: representatives nominated by sponsors, bringing industry perspective; not a governing role. One representative is listed — Mark Szymanski (HeroDevs) — recorded as `volunteer`.

Excluded: the Project Representatives section (~30 people) forms the Extended Governance Committee (EGC) and represents individual projects (JReleaser, Hibernate, Quarkus, WildFly, etc.); these are project-level roles per the crawl scope rules and are not captured here. The Members section (~17 GitHub handles, no names/roles) is likewise excluded.

Contact: the org publishes a GitHub handle per person (captured in `contact` as `github:<handle>`); no email is published. Bios are published for the councilors, officers, and the advisory rep and are captured verbatim (one emoji stripped from Andres Almiray's bio for YAML safety). Note: "cealsair" publishes only the first name "Cesar"; recorded as published.

Not published (hence null): per-person email, and term dates for everyone except the three founding councilors.
