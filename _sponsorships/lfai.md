---
identifier: lfai
commonName: LF AI Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://raw.githubusercontent.com/lfai/lfai-landscape/main/landscape.yml
levelurl: https://lfaidata.foundation/join/
landscape: LF AI & Data Member Company
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/lfai/lfai-landscape
    path: landscape.yml
    # LF Deep Learning (2018) became LF AI (2019), then LF AI & Data (2020)
    landscape: [LF AI & Data Member Company, LF AI Member Company, LF DL Member Company]
    levels:
      first:
        match: [Premier, Premium]
levels:
  first:
    name: Premier
    amount: '120000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: board seat
      advisory: voting rep on subcommittees
      marketing: press release
  second:
    name: General
    amount: '45000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      governance: can run for governance board
      advisory: access to staff
      marketing: submit vendor-neutral content to blog
      logo: 'yes'
  third:
    name: Associate
    amount: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
---
