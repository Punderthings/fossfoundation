---
identifier: lf
commonName: Linux Foundation
nonprofit: lf
# Experimental or sample value: x-prefixed keys are not read by the tools.
Xsponsorurl: https://lf-landscape.netlify.app/pages/members
sponsorurl: https://raw.githubusercontent.com/jmertic/lf-landscape/main/landscape.yml
levelurl: https://www.linuxfoundation.org/hubfs/lf_member_benefits_122723a.pdf?hsLang=en
normalize: 'true'
# Experimental or sample value: x-prefixed keys are not read by the tools.
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
    value: '500000'
    selector: div[data-section-id="lf-members-platinum"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
  second:
    name: Gold
    value: '100000'
    selector: div[data-section-id="lf-members-gold"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
  third:
    name: Silver
    value: '20000'
    selector: div[data-section-id="lf-members-silver"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
  fourth:
    name: Associate
    value: TBD
    selector: div[data-section-id="lf-members-associate"] > div
    attr: homepage_url
    benefits:
      governance: ''
      events: ''
      marketing: ''
      logo: ''
---
