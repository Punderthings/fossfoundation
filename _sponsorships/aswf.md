---
identifier: aswf
commonName: Academy Software Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://raw.githubusercontent.com/AcademySoftwareFoundation/aswf-landscape/main/landscape.yml
levelurl: https://www.aswf.io/join/
landscape: ASWF Member Company
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/AcademySoftwareFoundation/aswf-landscape
    path: landscape.yml
    # Repo began as a fork; its 2018 'LF DL Member Company' list belongs to LF AI, not ASWF
levels:
  first:
    name: Premier
    value: '50000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: appoint board seat
  second:
    name: General
    value: '20000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      governance: vote for board seat
      logo: 'yes'
  third:
    name: Associate
    value: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
---
