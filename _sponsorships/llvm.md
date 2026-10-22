---
identifier: llvm
commonName: LLVM Foundation
nonprofit: c3
sponsorurl: https://foundation.llvm.org/sponsors
levelurl: https://foundation.llvm.org/_files/ugd/449858_b2983cef7322479aa82160e0b3cb41de.pdf
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # 2020-2024: the earlier docs/sponsors page, a heading per tier followed by one or more blocks of logos
  - kind: wayback
    urls:
      - https://foundation.llvm.org/docs/sponsors/
    levels:
      first:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][@id='diamond-sponsors']]"
      second:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][@id='platinum-sponsors']]"
      third:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][@id='gold-sponsors']]"
      fourth:
        selector: "//a[starts-with(@href, 'http')][preceding::h2[1][@id='corporate-supporters']]"
  # 2024 on: the current sponsors page
  - kind: wayback
    urls:
      - https://foundation.llvm.org/sponsors
normalize: 'true'
comment: Amounts from the sponsorship document approved by the LLVM Foundation Board 2023-12-08; diamond is $100,000+
levels:
  first:
    name: diamond
    amount: '100000'
    selector: section.wixui-section:has(h4:contains("DIAMOND SPONSORS")) a[href^="http"]
    attr: href
    benefits:
      events: logo at event receptions; 10 event tickets
  second:
    name: platinum
    amount: '50000'
    selector: section.wixui-section:has(h4:contains("PLATINUM SPONSORS")) a[href^="http"]
    attr: href
    benefits:
      events: significant event visibility; 7 event tickets
  third:
    name: gold
    amount: '25000'
    selector: section.wixui-section:has(h4:contains("GOLD SPONSORS")) a[href^="http"]
    attr: href
    benefits:
      events: additional event visibility; 4 event tickets
  fourth:
    name: supporter
    amount: '2500'
    selector: section.wixui-section:has(h4:contains("CORPORATE SUPPORTERS")) a[href^="http"]
    attr: href
    benefits:
      advisory: seat on advisory committee
      events: 1 event discount
      logo: 'yes'
---
