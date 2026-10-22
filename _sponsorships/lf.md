---
identifier: lf
commonName: Linux Foundation
nonprofit: lf
Xsponsorurl: https://lf-landscape.netlify.app/pages/members
sponsorurl: https://raw.githubusercontent.com/jmertic/lf-landscape/main/landscape.yml
levelurl: https://www.linuxfoundation.org/hubfs/lf_member_benefits_122723a.pdf?hsLang=en
normalize: 'true'
xsponsormap: _data/lf_map.json
landscape: LF Members
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/jmertic/lf-landscape
    path: landscape.yml
    landscape: [LF Members, LF Member Company]
levels:
  first:
    name: Platinum
    amount: '500000'
    selector: div[data-section-id="lf-members-platinum"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
  second:
    name: Gold
    amount: '100000'
    selector: div[data-section-id="lf-members-gold"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
  third:
    name: Silver
    amount: '20000'
    selector: div[data-section-id="lf-members-silver"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
  fourth:
    name: Associate
    amount: TBD
    selector: div[data-section-id="lf-members-associate"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
---
