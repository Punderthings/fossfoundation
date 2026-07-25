---
identifier: spiinc
commonName: Software in the Public Interest, Inc.
asOf: 2026-07-25
sources:
- url: https://www.spi-inc.org/corporate/board/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Michael Schultheiss
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Director
    roleClass: board_director
  contact: president@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Jonatas L. Nogueira
  personId: null
  roles:
  - role: Vice President
    roleClass: officer
  - role: Director
    roleClass: board_director
  contact: vicepresident@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Jeremy Stanley
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  - role: Director
    roleClass: board_director
  contact: fungi@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Héctor Orón Martínez
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Director
    roleClass: board_director
  contact: treasurer@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Forrest Fleming
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: fsf@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Milan Kupcevic
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: milan@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Katherine McMillan
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: kmcmillan@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Borden Rhodes
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: borden@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
- name: Gordian Edenhofer
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: gordian.edenhofer@spi-inc.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://www.spi-inc.org/corporate/board/
  derived: org_live
  confidence: 1.0
---

# Software in the Public Interest — Leadership

Scope: the SPI Board of Directors and officers (`/corporate/board/`). SPI is a US 501(c)(3) that acts as a fiscal sponsor / non-profit umbrella for many FOSS projects (e.g. Debian). SPI is run by its Board of Directors and the officers they select; the site states "all current officers are also directors", so the four officers each carry both an `officer` and a `board_director` role.

Officers: Michael Schultheiss (President), Jonatas L. Nogueira (Vice President), Jeremy Stanley (Secretary), Héctor Orón Martínez (Treasurer). Additional directors: Forrest Fleming, Milan Kupcevic, Katherine McMillan, Borden Rhodes, Gordian Edenhofer. Total 9 people.

Paid vs volunteer: SPI's board and officers are volunteers (it is a volunteer-run umbrella organisation). The site does not print the word "volunteers" on this page, but the model is volunteer governance; no `paid_staff` roles are listed. No `volunteer` role_class is applied to board/officer roles per the schema (those use `board_director`/`officer`).

Contact: unusually, SPI publishes a per-person role email address for every board member (captured in `contact`). Several also list an OFTC IRC nick (schultmc, jesusalva, fungi, zumbi, fsf, milan, kmcmillan, borden, gordian) — noted here rather than in the structured `contact` field. Bios: not published (`null`). Term dates: not published (`null`).
