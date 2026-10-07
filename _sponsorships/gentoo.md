---
identifier: gentoo
commonName: Gentoo
nonprofit: c3
staticmap: '20240212'
sponsorurl: https://gentoo.org/inside-gentoo/sponsors/
levelurl: https://gentoo.org/inside-gentoo/sponsors/
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # _data/sponsors.yaml behind gentoo.org: hosting sponsors, specific donations, and former sponsors (not counted)
  - kind: git
    repo: https://anongit.gentoo.org/git/sites/www.git
    path: _data/sponsors.yaml
    sourcetype: yaml
    json:
      itemsByKey: true
      url: link
      name: name
      level: _key
    levels:
      firstinkind:
        match: hosting
      secondinkind:
        match: specific
normalize: 'true'
comment: 'Note: Gentoo doesn''t list specific level amounts, so cash value is estimated.'
levels:
  firstinkind:
    name: Premium
    amount: '5000'
    benefits:
      logo: 'yes'
    sponsors:
    - osuosl.org
    - bytemark.co.uk
    - 7l.com
    - top-ix.org
    - fastbull.org
    - dedicatednow.com
    - hotelkatalog24.de
    - numberly.com
    - leaseweb.com
    - hetzner.com
    - cdn77.com
    - vsys.host
    - hp.com
    - eng.mephi.ru
  secondinkind:
    name: Specific Donations
    amount: '1000'
    benefits:
      logo: 'yes'
    sponsors:
    - nitrokey.com
    - imgtec.com
    - opengear.com
    - nvidia.com
    - amigaforever.com
    - ostc.com
    - jetbrains.com
    - genesi.lu
    - datarescue.com
---
