---
identifier: fsfe
commonName: Free Software Foundation Europe
nonprofit: charitable e.V.
sponsorurl: https://fsfe.org/donate/thankgnus.en.html
levelurl: https://fsfe.org/donate/thankgnus.en.html
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # Yearly donor pages, each listing that year's donors; Gold/Silver headings until 2024
  - kind: yearly-page
    url: https://fsfe.org/donate/thankgnus-{year}.en.html
    until: '20241231'
    levels:
      first:
        selector: "h2#id-gold-donors + p + table td img"
      second:
        selector: "h2#id-silver-donors + p + table td img"
  # From 2025, untitled tables by amount (the current page's layout)
  - kind: yearly-page
    url: https://fsfe.org/donate/thankgnus-{year}.en.html
    from: '20250101'
normalize: 'false'
sponsormap: _data/fsfe_map.json
comment: "Levels are 18,000 / 3,600 / 720 EUR per year; the 720 EUR level lists names only (including individuals) and is not parsed"
# FSFE donor pages are per calendar year; thankgnus-2025 is the first with these amounts
effectiveDate: '20250101'
pastModels:
  # Gold/Silver/Bronze at 12,000 / 2,400 / 480 EUR per year on the 2019-2024 pages (earlier years not checked)
  - effectiveDate: '20190101'
    levelurl: https://fsfe.org/donate/thankgnus-2024.en.html
    levels:
      first:
        value: '12000'
      second:
        value: '2400'
levels:
  first:
    name: Gold
    value: '18000'
    currency: EUR
    selector: "div#content > table:nth-of-type(1) td img"
    attr: 'alt'
    benefits:
      logo: 'yes'
  second:
    name: Silver
    value: '3600'
    currency: EUR
    selector: "div#content > table:nth-of-type(2) td img"
    attr: 'alt'
    benefits:
      logo: 'yes'
---