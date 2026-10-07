---
identifier: eclipse
commonName: Eclipse
nonprofit: c6
sponsorurl: https://membership.eclipse.org/api/organizations?pagesize=100
sourcetype: json
# Same API the explore-membership page loads with JavaScript; members without a website are listed by name
json:
  url: website
  name: name
  level: levels.description
levelurl: https://www.eclipse.org/membership/documents/membership-prospectus.pdf
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # Before 2022 the explore-membership page linked members to internal profile ids, not
  # websites; mapping those ids needs each member's profile page, so it is not collected yet.
  # Captures of the membership API that the page has loaded since 2022
  - kind: wayback
    urls:
      - https://membership.eclipse.org/api/organizations?pagesize=100
    from: '20220101'
levels:
  first:
    name: Strategic
    amount: '300000'
    amountCurrency: EUR
    amountVaries: sliding scale by corporate revenues
    match: Strategic Member
    benefits:
      governance: board seat
      advisory: can lead working groups; seat on Foundation councils
      events: additional event discounts
      services: IP analysis and reporting
      marketing: access to marketing programs
      logo: yes, premium spot in conferences
  second:
    name: Contributing
    amount: '25000'
    amountCurrency: EUR
    amountVaries: sliding scale by corporate revenues
    match: Contributing Member
    benefits:
      governance: can vote in board elections
      advisory: can join working groups as voting member
      events: ticket and sponsorship discounts
      marketing: access to marketing programs
      logo: yes
  third:
    name: Associate
    amount: '25000'
    amountCurrency: EUR
    amountVaries: sliding scale by corporate revenues; 0 for nonprofits
    match: Associate Member
    benefits:
      advisory: can join working groups as guest
      logo: yes
---
