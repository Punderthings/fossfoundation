---
identifier: opencompute
commonName: Open Compute Project Foundation
asOf: 2026-07-25
sources:
- url: https://en.wikipedia.org/wiki/Open_Compute_Project
  type: org_live
  retrieved: 2026-07-25
- url: https://www.opencompute.org/about/board-of-directors
  type: org_live
  retrieved: 2026-07-25
people:
- name: David Ramku
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
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Andy Bechtolsheim
  personId: null
  roles:
  - role: Board Director (individual member)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Mohamed Awad
  personId: null
  roles:
  - role: Board Director (Arm)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Saurabh Dighe
  personId: null
  roles:
  - role: Board Director (Microsoft)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Robert Hormuth
  personId: null
  roles:
  - role: Board Director (AMD)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Amber Huffman
  personId: null
  roles:
  - role: Board Director (Google)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Jeff McVeigh
  personId: null
  roles:
  - role: Board Director (Intel)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: Rob Ober
  personId: null
  roles:
  - role: Board Director (NVIDIA)
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
- name: George Tchaparian
  personId: null
  roles:
  - role: Chief Executive Officer
    roleClass: paid_staff
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://en.wikipedia.org/wiki/Open_Compute_Project
  derived: synthesized
  confidence: 0.7
---

# Open Compute Project Foundation — Leadership

Provenance caveat: the OCP live site (opencompute.org/about/board-of-directors and /about/foundation-staff) returns HTTP 403 to automated fetches (Cloudflare/bot protection), so this roster could NOT be captured from the org's live pages directly. It is derived from the English Wikipedia article "Open Compute Project" (last edited 2 July 2026), which cites the OCP board-of-directors page (archived 2026-05-21, retrieved 2026-07-01). All records are therefore tagged `derived: synthesized` with `confidence: 0.7` pending live-site confirmation. This matches the standing quality flag on OCP.

Scope: the OCP Board of Directors. Wikipedia states (as of July 2026) that the board has "eight members ... one individual member and seven organizational members": Andy Bechtolsheim (individual), plus organizational representatives David Ramku (Meta, Board Chair), Mohamed Awad (Arm), Saurabh Dighe (Microsoft), Robert Hormuth (AMD), Amber Huffman (Google), Jeff McVeigh (Intel), and Rob Ober (NVIDIA). The same sentence also lists OCP CEO George Tchaparian on the board; including him yields nine named individuals against a stated count of eight, so treat the exact board composition (whether the CEO is a voting board member) as unconfirmed. George Tchaparian is captured as CEO (`paid_staff`) and, per Wikipedia's phrasing, also as a board director.

Paid vs volunteer: the organizational board seats are corporate representatives (governance, unpaid by OCP). George Tchaparian is OCP's employed CEO (`paid_staff`).

Not captured: OCP foundation staff (e.g. names surfaced in search snippets such as Bijan Nowroozi and Cliff Grossner) could NOT be reliably enumerated because the /about/foundation-staff page also 403s; these are deliberately omitted rather than fabricated from partial snippets. Contact, bios, and term dates are not published (all `null`).

Retry note: re-fetch opencompute.org/about/board-of-directors and /about/foundation-staff from a browser session or wayback capture to upgrade these records to `org_live` / `confidence: 1.0` and to add the staff roster.
