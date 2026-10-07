---
identifier: cd
commonName: CD Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://raw.githubusercontent.com/cdfoundation/cdf-landscape/main/landscape.yml
levelurl: https://cd.foundation/members/join/
landscape: CDF Members
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/cdfoundation/cdf-landscape
    path: landscape.yml
    levels:
      first:
        match: [Premier, Platinum]
      third:
        match: [End User, End User Supporter]
levels:
  first:
    name: Premier
    amount: '100000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: appoint board seat
      marketing: press release
  second:
    name: General
    amount: '30000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      governance: vote for board seat
      advisory: expanded access to council, jobs postings
  third:
    name: End User
    amount: '15000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      advisory: access to end user council
      services: access to job posting board
      events: sponsorship discounts
      logo: 'yes'
  community:
    name: Associate
    amount: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
---
