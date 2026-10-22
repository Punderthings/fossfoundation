---
identifier: cncf
commonName: Cloud Native Computing Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://raw.githubusercontent.com/cncf/landscape/master/landscape.yml
levelurl: https://www.cncf.io/about/join/
normalize: 'true'
landscape: CNCF Members
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/cncf/landscape
    path: landscape.yml
  # Before mid-2020 landscape.yml had no member categories; captures of the members page instead.
  # 'End User Members' are paying members already listed under their tier, so they are not counted again.
  - kind: wayback
    urls:
      - https://www.cncf.io/about/members/
    until: '20200630'
    sourcetype: css
    normalize: 'true'
    replaceLevels: true
    levels:
      first:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(., 'Platinum Members')]]"
        attr: href
      second:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(., 'Gold Members')]]"
        attr: href
      third:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(., 'Silver Members')]]"
        attr: href
      community:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(., 'Academic / Nonprofit Members')]]"
        attr: href
      enduser:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(., 'End User Supporters')]]"
        attr: href
levels:
  first:
    name: Platinum
    amount: '370000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: Board seat appointment
      advisory: Personal connections in project
      events: KubeCon keynote slot
      services: Multiple training/certification discounts
      marketing: Press release; Can host/run live branded webinars
      logo: 'Featured prominently, (note: this level requires 3 year commitment)y'
  second:
    name: Gold
    amount: '120000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: ''
      advisory: Quarterly meeting with execs
      events: Improved event access
      services: 50 seats training subscription
      marketing: ''
      logo: ''
  third:
    name: Silver
    amount: '50000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: Can run for board seats
      advisory: ''
      events: ''
      services: 10 seats training subscriptions
      marketing: Submit vendor-neutral content to social medias
      logo: ''
  academic:
    name: Academic
    amount: '1000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: ''
      advisory: ''
      events: Event discounts
      services: ''
      marketing: ''
      logo: Logo display included
  community:
    name: Nonprofit
    amount: '1000'
    selector: ''
    attr: homepage_url
  enduser:
    name: End User Supporter
    match:
      - End User Supporter
      - End User Supporter and Contributor
    amount: '0'
    selector: ''
    attr: ''
---
