---
identifier: hyperledger
commonName: Hyperledger
fiscalHost: lf
nonprofit: lf
sponsorurl: https://landscape.lfdecentralizedtrust.org/data/full.json
sourcetype: landscapejson
levelurl: https://www.hyperledger.org/join-us
landscape: LF Decentralized Trust Members
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/hyperledger-dlt-landscape/hyperledger-dlt-landscape
    path: landscape.yml
    # The landscape.yml behind the LF Decentralized Trust landscape site
    sourcetype: landscape
    landscape: [LF Decentralized Trust Members, Hyperledger Members]
levels:
  first:
    name: Premier
    amount: '250000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: must be LF foundation member
  second:
    name: General
    amount: '50000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      governance: must be LF foundation member
      logo: 'yes'
  third:
    name: Associate
    amount: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
---
