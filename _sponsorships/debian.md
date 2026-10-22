---
identifier: debian
commonName: Debian
fiscalHost: spi
nonprofit: c3
sponsorurl: https://www.debian.org/partners/
levelurl: https://www.debian.org/partners/2024/partners
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # Internet Archive captures of the partners page
  - kind: wayback
    urls:
      - https://www.debian.org/partners/
normalize: 'true'
comment: Debian uses SPI fiscal hosting; no specific level is set so estimate at 1001
levels:
  first:
    name: Partner
    amount: '1001'
    selector: div.partnerlogo a
    attr: href
    benefits:
      logo: 'yes'
---
