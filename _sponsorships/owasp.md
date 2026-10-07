---
identifier: owasp
commonName: OWASP
nonprofit: c3
sponsorurl: https://owasp.org/api/public/corporate-supporters/list
sourcetype: json
# Public API behind https://owasp.org/supporters/bios
json:
  items: supporters
  url: website_url
  name: name
  level: tier
  filter:
    status: active
levelurl: https://owasp.org/supporters
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # corp_members.yml behind the owasp.org Jekyll site (2019 on): corporate supporters
  # are member: true.  Until August 2021 the file had no tiers, so members are 'listed'.
  - kind: git
    repo: https://github.com/OWASP/owasp.github.io
    path: _data/corp_members.yml
    until: '20210731'
    sourcetype: yaml
    json:
      url: url
      name: name
      level: member
      filter:
        member: 'true'
    replaceLevels: true
    levels:
      listed:
        name: Corporate Supporter
        match: 'true'
  # From August 2021, tier by membertype (2 Platinum, 3 Gold, 4 or missing Silver)
  - kind: git
    repo: https://github.com/OWASP/owasp.github.io
    path: _data/corp_members.yml
    from: '20210801'
    sourcetype: yaml
    json:
      url: url
      name: name
      level: membertype
      defaultLevel: third
      filter:
        member: 'true'
    levels:
      first:
        match: '2'
      second:
        match: '3'
      third:
        match: '4'
normalize: 'true'
levels:
  first:
    name: platinum
    amount: '25000'
    benefits:
      events: early event access; 20 discount tickets
      marketing: 10 projects/chapters to sponsor
  second:
    name: gold
    amount: '15000'
    benefits:
      events: 10 discount tickets
      marketing: 5 projects/chapters to sponsor
  third:
    name: silver
    amount: '5000'
    benefits:
      events: 2 discount tickets
      marketing: 1 projects/chapters to sponsor
---
