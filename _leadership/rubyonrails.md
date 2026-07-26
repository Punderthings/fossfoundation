---
identifier: rubyonrails
commonName: The Rails Foundation
asOf: 2026-07-25
sources:
- url: https://rubyonrails.org/foundation
  type: org_live
  retrieved: 2026-07-25
people:
- name: David Heinemeier Hansson
  personId: null
  roles:
  - role: Board Chair
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Creator of Ruby on Rails; chairs the foundation's board. Trademark owner of the Rails trademarks,
    licensed exclusively to the foundation.
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Linh Dam
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Co-Founder and Chief Architect, Judge.me
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Steve Davis
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: President of Product & Technology, Procore
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Rafael França
  personId: null
  roles:
  - role: Board Director (Interim)
    roleClass: board_director
  contact: null
  bio: Principal Engineer, Shopify
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Rosa Gutiérrez
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Lead Programmer, 37signals
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Whitney Imura
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: VP of Engineering, GitHub
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Jason Meller
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: VP, Product, 1Password
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Bruno Miranda
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: SVP, Engineering, Doximity
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Ryan Sherlock
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Director of Engineering, Fin
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Jorge Valdivia
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: CTO, Fleetio
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Miles Woodroffe
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Technical Advisor to the CEO, Cookpad
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
- name: Amanda Perino
  personId: null
  roles:
  - role: Executive Director
    roleClass: paid_staff
  contact: amanda@rubyonrails.org
  bio: null
  termStart: null
  termEnd: null
  sourceUrl: https://rubyonrails.org/foundation
  derived: org_live
  confidence: 1.0
---

# The Rails Foundation — Leadership

Scope of this record: the foundation's Board (chair + 10 directors) and its Executive Director, as published on the /foundation page. The Rails Foundation is a US 501(c)(6) non-profit that funds documentation, education, marketing, and events for the Ruby on Rails ecosystem and administers the Rails trademarks under an exclusive licence.

Board composition: each of the ten Core member companies is represented by one employee on the board, which is chaired by David Heinemeier Hansson, the creator of Ruby on Rails and the Rails trademark owner. Rafael França (Shopify) is listed as an interim board member; this is captured in his role string and noted here.

Bios: the foundation publishes a short affiliation line for each board director (their day-job title and company, e.g. "CTO, Fleetio"). These verbatim lines are stored in `bio`. They describe the individual's external role, not a foundation biography, but are the org-published descriptor for each person.

Paid vs volunteer: Amanda Perino is the Executive Director (paid_staff, explicit title) and is the only staff role published; the board directors are company representatives serving in a governance capacity, not foundation employees.

Contact: the foundation publishes a direct email only for the Executive Director (amanda@rubyonrails.org), captured in `contact` at confidence 1.0. Board directors link to LinkedIn profiles (external biographical links suited to the Who's Who dataset), so their per-person `contact` is null. The org-level address is foundation@rubyonrails.org.

Term dates: not published for any individual, so `term_start`/`term_end` are null.

Not captured: the corporate members (ten Core members: Cookpad, Doximity, Fin, Fleetio, GitHub, Judge.me, Procore, Shopify, 1Password, 37signals; plus fourteen Contributing members) are organisations, not individuals, and so are out of scope for this people-leadership dataset.
