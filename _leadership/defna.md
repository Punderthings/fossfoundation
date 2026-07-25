---
identifier: defna
commonName: Django Events Foundation North America
asOf: 2026-07-25
sources:
- url: https://www.defna.org/about/
  type: org_live
  retrieved: 2026-07-25
people:
- name: Peter Grandstaff
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Peter is a Django developer and co-founder of Two Rock Software, a North Carolina based software
    development company specializing in business workflow automation. He also enjoys solving devops puzzles.
    When he's not working he loves exploring new foods, gardening, and movement practices like martial
    arts, aerial dance, and contact improv.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Velda Kiara
  personId: null
  roles:
  - role: Vice President
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Velda Kiara is a passionate software developer and technical writer with a love for crafting Python
    code, particularly for Django. She actively contributes to open-source projects, sharing her knowledge
    and enhancing both code and documentation. Beyond her technical contributions, she contributes to
    Djangonaut Space by writing Django News Updates and maintaining the Django Debug Toolbar, among other
    projects. Her dedication and technical contributions to Python and Django communities have earned
    her recognition as a Microsoft Most Valuable Professional for Python and Web technologies.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Miguel Sanda
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Miguel Sanda is a software developer, data scientist, and entrepreneur with over 18 years of experience
    spanning the energy, food, and financial industries. As the creator and lead developer of Django Ledger,
    an open-source financial engine built on the Django framework, Miguel has dedicated his career to
    bridging the gap between software development and financial management.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Nathan Zeager
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Nathan is a software developer, barista, and co-founder of Bismuth Cooperative, a freelance web
    development company. He enjoys thinking about user experience and working with a team to accomplish
    a goal. When not working he enjoys spending time with his dogs, playing video games, watching tv,
    and going on hikes.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Carol Ganz
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Carol is VP of Sales for Six Feet Up, a Python and Cloud software consultancy. She is a highly
    organized and effective leader who strives to get the best out of people. A very personable and empathetic
    team player, Carol loves getting involved in community events. She is stoked to contribute to advancing
    the DEFNA mission. When not working Carol likes to spend time hanging out with her family, working
    in the yard and volunteering at the community theater.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Adam Fast
  personId: null
  roles:
  - role: Director and A/V Chair
    roleClass: board_director
  contact: null
  bio: Adam has been Django obsessed for many years and enjoys finding ways to combine Python and Django
    with GIS, amateur radio and aviation whenever possible. He also has a background in audio visual,
    control systems and live event production. He has published a number of open source aviation and geographic
    data related Django apps. He works for JBS Solutions as a Senior Developer. His favorite hobby is
    flying small airplanes even when there's no place to go.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Jeff Triplett
  personId: null
  roles:
  - role: Co-Founder
    roleClass: board_director
  contact: null
  bio: Jeff is a Django developer for Revolution Systems (REVSYS) and is a Director and Vice Chair for
    the Python Software Foundation.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
- name: Drew Winstel
  personId: null
  roles:
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Drew is a software developer living in the Huntsville, Alabama area who has been developing with
    Django (primarily in REST Framework apps) since 2014. He spoke at DjangoCon US in 2018 and was Opportunity
    Grants chair for the same conference in 2019 and 2021. He was also DCUS Program Chair in 2021-23.
    He currently works as a backend engineer for The Noun Project. When not working, he can be found cycling,
    brewing beer, hiking, cooking, coaching and refereeing youth soccer, and chasing his young daughter
    and/or pets.
  termStart: null
  termEnd: null
  sourceUrl: https://www.defna.org/about/
  derived: org_live
  confidence: 1.0
---

# Django Events Foundation North America — Leadership

Scope of this record: the current DEFNA Board of Directors listed on the About page. DEFNA is a California 501(c)(3) nonprofit founded in 2015 at the Django Software Foundation's request; it organizes DjangoCon US and funds community events.

Paid vs volunteer: the org states it "is governed by a volunteer board" and describes the board as "Nine volunteers who keep DEFNA running". All directors and officers are therefore tagged `volunteer`/`board_director` and `officer` with the paid-vs-volunteer status stated (confidence 1.0). DEFNA lists no paid staff (Executive Director or similar) on the About page.

Count discrepancy: the About page heading states "Nine volunteers" but only eight current directors are individually listed under "Board of Directors" (Grandstaff, Kiara, Sanda, Zeager, Ganz, Fast, Triplett, Winstel). Eight are captured here; the ninth is not individually published on this page.

Excluded (historical, not current): the page also lists "Board Members Emeriti" (Tim Schilling) and "Past Board Members" / alumni (Katia Lira, Stacey Haysler, Kojo Idrissa, Heather Luna, Craig Bruce, Nicole Dominguez, Monique Murphy, Josue Balandrano Coronel, Aaron Bassett, Logan Kilpatrick, Jennifer Myers, Katherine 'Kati' Michel). These belong in the leadership-history dataset, not the current roster.

Field availability: bios are published verbatim for all eight and captured. Per-person contact email is not published (`contact: null`); the org does publish social/GitHub/website links per person, which suit the Who's Who dataset. No term_start/term_end dates are stated anywhere (`null`).
