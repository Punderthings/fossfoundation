---
identifier: graphql
commonName: GraphQL Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://raw.githubusercontent.com/graphql/graphql-landscape/main/landscape.yml
levelurl: https://graphql.org/foundation/join/
landscape: GraphQL Foundation Member
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/graphql/graphql-landscape
    path: landscape.yml
levels:
  first:
    name: General
    amount: '20000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      governance: vote for board seat; must be LF Silver member
  community:
    name: Associate
    amount: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
---
