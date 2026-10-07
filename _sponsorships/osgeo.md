---
identifier: osgeo
commonName: OSGEO
nonprofit: c3
sponsorurl: https://www.osgeo.org/sponsors/
levelurl: https://www.osgeo.org/sponsors/
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # Until 2018: a heading per tier (h2 or h3) followed by sponsor links
  - kind: wayback
    urls:
      - https://www.osgeo.org/sponsors/
    until: '20181231'
    levels:
      first:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'diamond sponsors')]]"
      second:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'platinum sponsors')]]"
      third:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'gold sponsors')]]"
      fourth:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'silver sponsors')]]"
      fifth:
        selector: "//a[starts-with(@href, 'http')][preceding::*[self::h2 or self::h3][1][contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'bronze sponsors')]]"
  # From 2019: class-based sections (the current page's layout)
  - kind: wayback
    urls:
      - https://www.osgeo.org/sponsors/
    from: '20190101'
normalize: 'true'
levels:
  first:
    name: diamond
    amount: '30000'
    selector: ".Diamond-sponsors a"
    attr: href
    benefits:
      events: event invite and featured booth
      marketing: press release
      logo: logo in site footer and About OSGeo page
  second:
    name: platinum
    amount: '20000'
    selector: ".Platinum-sponsors a"
    attr: href
    benefits:
      events: event invite and featured booth
      marketing: press release
      logo: logo in site footer and About OSGeo page
  third:
    name: gold
    amount: '10000'
    selector: ".Gold-sponsors  a"
    attr: href
    benefits:
      events: event invite
      marketing: blog posting announcement
      logo: logo in site footer
  fourth:
    name: silver
    amount: '3000'
    selector: ".Silver-sponsors  a"
    attr: href
    benefits:
      events: event invite
      marketing: blog posting announcement
      logo: logo in site footer
  fifth:
    name: bronze
    amount: '500'
    selector: ".Bronze-sponsors a"
    attr: href
    benefits:
      logo: small logo
---
