---
identifier: finos
commonName: FINOS Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://www.finos.org/members
xsponsorurl: https://raw.githubusercontent.com/finos/finos-landscape/master/landscape.yml
levelurl: https://www.finos.org/membership-benefits
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # Internet Archive captures of the members page; every layout since 2018 has a heading per tier
  - kind: wayback
    urls:
      - https://www.finos.org/members
    levels:
      first:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][contains(translate(normalize-space(.), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), 'PLATINUM MEMBERS')]]"
      second:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][contains(translate(normalize-space(.), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), 'GOLD MEMBERS')]]"
      third:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][contains(translate(normalize-space(.), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), 'SILVER MEMBERS')]]"
      community:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][contains(translate(normalize-space(.), 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'), 'ASSOCIATE MEMBERS')]]"
xlandscape: FINOS Members - note landscape isn't actually used for members!
normalize: 'true'
levels:
  first:
    name: Platinum
    amount: '200000'
    selector: div#platinum a.hs-logo-grid__logo-link
    attr: href
    benefits:
      governance: appoint board seat
  second:
    name: Gold
    amount: '50000'
    selector: div#gold a.hs-logo-grid__logo-link
    attr: href
    benefits:
      governance: vote for gold board seat
      logo: 'yes'
  third:
    name: Silver
    amount: '30000'
    amountvaries: sliding scale by number employees
    selector: div.row-depth-1:has(h2:contains("SILVER MEMBERS")) + div.row-depth-1 a.hs-logo-grid__logo-link
    attr: href
    benefits:
      governance: vote for silver board seat
      events: access at events
      logo: 'yes'
  community:
    name: Associate
    amount: '0'
    # Associates have no section id of their own; they follow their heading inside the silver section
    selector: div.row-depth-1:has(h2:contains("ASSOCIATE MEMBERS")) + div.row-depth-1 a.hs-logo-grid__logo-link
    attr: href
    benefits:
      logo: 'yes'
---
