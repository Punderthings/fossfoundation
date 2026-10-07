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
