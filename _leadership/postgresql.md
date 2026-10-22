---
identifier: postgresql
commonName: United States PostgreSQL Association
asOf: 2026-07-25
sources:
- url: https://postgresql.us/team
  type: org_live
  retrieved: 2026-07-25
people:
- name: Stacey Haysler
  personId: null
  roles:
  - role: President
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Stacey Haysler is the CFO and COO of PostgreSQL Experts, Inc. She first became involved in the
    Postgres community in 2010, and has worked as an organizer and conference staff for a number of conferences,
    both in North America and Europe, as well as being part of the start up team for PgDay San Francisco.
    She founded the Django Events Foundation North America (DEFNA), a nonprofit associated with the Django
    Software Foundation, and was a principal organizer of DjangoConUS for three years. She also served
    as Treasurer of the DSF for a year while starting DEFNA. She is a PostgreSQL contributor. She worked
    with the Core Team to develop the PostgreSQL Community Code of Conduct in 2017, and served as the
    Chair of the Community Code of Conduct Committee through September 2021.
  termStart: null
  termEnd: 2027-04-30
  sourceUrl: https://postgresql.us/team
  derived: org_live
  confidence: 1.0
- name: Mark Wong
  personId: null
  roles:
  - role: Treasurer
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Mark Wong is currently employed by pgEdge and is a PostgreSQL Major Contributor. His background
    is in database systems solutions and performance. He first introduced himself to the PostgreSQL community
    in 2003 with open source benchmarking kits and performance data. Since then, he has continued to contribute
    to various aspects of the community such as a Google Summer of Code mentor, event planner, Portland
    PostgreSQL Users Group Co-Organizer, PostgreSQL Fundraising Group Member, and Director of PgUS.
  termStart: null
  termEnd: 2028-04-30
  sourceUrl: https://postgresql.us/team
  derived: org_live
  confidence: 1.0
- name: Michael Brewer
  personId: null
  roles:
  - role: Secretary
    roleClass: officer
  - role: Board Director
    roleClass: board_director
  contact: null
  bio: Michael Brewer is a Web Developer Principal in the Franklin College Office of Information Technology
    at The University of Georgia. Michael's responsibilities include developing applications for intranet
    and internet use, creating and managing databases, and desktop and network support. One of the applications
    he developed won a national award for innovation in advising technology. He is one of the founding
    board members of the United States PostgreSQL Association.
  termStart: null
  termEnd: 2028-04-30
  sourceUrl: https://postgresql.us/team
  derived: org_live
  confidence: 1.0
- name: Elizabeth Garrett Christensen
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: null
  bio: Elizabeth Garrett Christensen works on Postgres educational content at Snowflake. She writes blogs,
    tutorials, and product documentation while also assisting with Postgres product development. Elizabeth
    organizes the global PostGIS Day and hosts a local Kansas City Postgres User Group. Elizabeth enjoys
    speaking at Postgres events, open source events, and developer conferences primarily for users new
    to Postgres or in non-traditional technical roles. Elizabeth has a B.A. in Archeology from the University
    of Texas and a background in academic publishing software and open-source software.
  termStart: null
  termEnd: 2027-04-30
  sourceUrl: https://postgresql.us/team
  derived: org_live
  confidence: 1.0
- name: Valerie Parham-Thompson
  personId: null
  roles:
  - role: Director
    roleClass: board_director
  contact: null
  bio: Valerie Parham-Thompson is a Database Solutions Architect; she focuses on data architecture for
    high-traffic applications, and is a frequent writer on Postgres, spatial data, and routing. Valerie
    has over two decades of experience scaling data systems, and has previously worked as a solutions
    architect at YugabyteDB and a principal consultant at Pythian. Valerie takes an active role in shaping
    her tech communities, organizing meetups like the Triangle Postgres Users Group, judging youth technical
    competitions like Technovation, and providing technical editing for Manning Publications and others.
    She holds a degree from UNC-Chapel Hill Kenan-Flagler Business School and has spent most of her life
    working with startups.
  termStart: null
  termEnd: 2028-04-30
  sourceUrl: https://postgresql.us/team
  derived: org_live
  confidence: 1.0
---

# United States PostgreSQL Association (PgUS) — Leadership

Scope of this record: the PgUS Board of Directors and its officers. PgUS is a 501(c)(3) public charity supporting PostgreSQL growth and education in the United States. The board is elected by the membership; three seats were up in the April 2026 election.

Officer roles (President, Treasurer, Secretary) are held by directors, so those individuals carry both an `officer` role and an implicit board seat; they are tagged with both role classes. Elizabeth Garrett Christensen and Valerie Parham-Thompson serve as Directors without a named officer role.

Paid vs volunteer: PgUS is a volunteer-run association; directors and officers are unpaid community volunteers. No paid staff (Executive Director or similar) is published.

Term dates: PgUS publishes explicit term-end dates per director on its board page ("Current term runs through April 30, YYYY"), which are captured verbatim in `term_end`. Term-start dates are not stated, so `term_start` is null. Valerie Parham-Thompson began her first term following the 2026 election (per the news item), but a specific start date is not published, so `term_start` remains null.

Contact: not published per person. The org publishes list addresses only (board@postgresql.us, elections@postgresql.us), which are organisational, not individual, so per-person `contact` is null.

Provenance: all data from the live PgUS board page (https://postgresql.us/team), which renders the same roster shown on the homepage. Bios and term-end dates are verbatim; confidence 1.0 throughout.
