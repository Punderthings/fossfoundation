---
identifier: osgeo
commonName: Open Source Geospatial Foundation
asOf: 2026-07-25
sources:
- url: https://www.osgeo.org/about/board/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Jeroen Ticheler
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: president@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Codrina Maria Ilie
  personId: null
  roles:
  - role: Vice-President Europe
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: codrina.ilie@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Marco Bernasocchi
  personId: null
  roles:
  - role: Vice-President Oceania
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: marco.bernasocchi@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Tim Sutton
  personId: null
  roles:
  - role: Vice-President Africa
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: tim.sutton@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Tom Kralidis
  personId: null
  roles:
  - role: Vice-President North America
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: tomkralidis@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Vicky Vergara
  personId: null
  roles:
  - role: Vice-President South America and Asia
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: vicky.vergara@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Angelos Tzotsos
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: tzotsos@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Joana Simoes
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: joana.simoes@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Michael Smith
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: treasurer@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
- name: Astrid Emde
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  contact: secretary@osgeo.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.osgeo.org/about/board/
  derived: org_live
  confidence: 1.0
---

# Open Source Geospatial Foundation (OSGeo) — Leadership

Scope of this record: the OSGeo Board of Directors and the appointed officers (Positions), captured from the live "Board and Officers" page.

Board: OSGeo Charter Members elect a 9-member Board of Directors, who appoint officers and set the vision and goals for the Foundation. The nine elected directors are Jeroen Ticheler, Tom Kralidis, Tim Sutton, Angelos Tzotsos, Michael Smith, Codrina Maria Ilie, Vicky Vergara, Joana Simoes, and Marco Bernasocchi.

Officers (Positions): the President, five regional Vice-Presidents, Treasurer, and Secretary are captured. Eight of the ten officer posts are held by sitting board directors (their board seat and officer role are merged into one person record each). The Secretary, Astrid Emde, is an appointed officer who is not one of the nine elected directors, so she is recorded with the `officer` role only.

Paid vs volunteer: OSGeo governance is volunteer-run (Charter Members elect the board; the board empowers volunteer committees). The page does not print an explicit "volunteers" statement, so board and officer roles are captured `board_director`/`officer` at confidence 1.0 for the fact of the role, with volunteer (unpaid) status inferred from the foundation's structure rather than a verbatim statement.

Contact: OSGeo publishes an `@osgeo.org` address for each officer, so `contact` is populated at confidence 1.0. Regional VPs use personal-form addresses (e.g. codrina.ilie@osgeo.org); the President, Treasurer, and Secretary are published against role aliases (president@ / treasurer@ / secretary@osgeo.org), captured as given.

Not published (hence `null`): bios and term dates. Board term history lives at the OSGeo wiki ("History of OSGeo Foundation Boards of Directors"), which is the source for the leadership-history dataset.

Excluded (project/committee-level, not foundation governance): the long list of committee VPs (Conference, Finance, GeoforAll, Incubation, Marketing, Public Geospatial Data, System Administration, UN, Standards) and the ~25 OSGeo Project Officers (per-project VPs for GDAL, GEOS, GeoServer, QGIS, PostGIS, etc.). These are operational roles for committees and software projects and are deliberately not captured as foundation leadership; they could form a separate project-roles dataset if wanted.
