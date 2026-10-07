---
identifier: fsfe
commonName: Free Software Foundation Europe
nonprofit: charitable e.V.
sponsorurl: https://fsfe.org/donate/thankgnus.en.html
levelurl: https://fsfe.org/donate/thankgnus.en.html
normalize: 'false'
sponsormap: _data/fsfe_map.json
comment: "Levels are 18,000 / 3,600 / 720 EUR per year; the 720 EUR level lists names only (including individuals) and is not parsed"
levels:
  first:
    name: Gold
    amount: '18000'
    amountCurrency: EUR
    selector: "div#content > table:nth-of-type(1) td img"
    attr: 'alt'
    benefits:
      logo: 'yes'
  second:
    name: Silver
    amount: '3600'
    amountCurrency: EUR
    selector: "div#content > table:nth-of-type(2) td img"
    attr: 'alt'
    benefits:
      logo: 'yes'
---