---
identifier: finos
commonName: FINOS Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://www.finos.org/members
xsponsorurl: https://raw.githubusercontent.com/finos/finos-landscape/master/landscape.yml
levelurl: https://www.finos.org/membership-benefits
xlandscape: FINOS Members - note landscape isn't actually used for members!
normalize: 'true'
levels:
  first:
    name: Platinum
    amount: '200000'
    selector: div#platinum div.member_item a
    attr: href
    benefits:
      governance: appoint board seat
  second:
    name: Gold
    amount: '50000'
    selector: div#gold div.member_item a
    attr: href
    benefits:
      governance: vote for gold board seat
      logo: 'yes'
  third:
    name: Silver
    amount: '30000'
    amountvaries: sliding scale by number employees
    selector: div#silver div.member_item a
    attr: href
    benefits:
      governance: vote for silver board seat
      events: access at events
      logo: 'yes'
  community:
    name: Associate
    amount: '0'
    selector: div#notfound this section doesn't have an id is just in the silver section
    attr: href
    benefits:
      logo: 'yes'
---
