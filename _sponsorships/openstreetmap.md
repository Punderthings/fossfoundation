---
identifier: openstreetmap
commonName: OpenStreetMap
nonprofit: LimitedByGuaranteeCharity
sponsorurl: https://osmfoundation.org/wiki/Corporate_Members
levelurl: https://osmfoundation.org/wiki/Join_as_a_corporate_member
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  # Revisions of the Corporate Members wiki page, rendered by the wiki API, in three layouts.
  # Until 2017-03-20 one list without tiers: every external link is a member.
  - kind: wiki
    api: https://osmfoundation.org/w/api.php
    title: Corporate_Members
    until: '20170320'
    replaceLevels: true
    levels:
      listed:
        name: Corporate Member
        selector: "a[href^='http']:not([href*='osmfoundation.org'])"
        attr: href
  # 2017-03-21 to 2018-04-29: one table per tier, titled inside the table: Gold, Bronze, Supporter
  - kind: wiki
    api: https://osmfoundation.org/w/api.php
    title: Corporate_Members
    from: '20170321'
    until: '20180429'
    replaceLevels: true
    levels:
      second:
        selector: "table:nth-of-type(1) a[href^='http']"
        attr: href
      fourth:
        selector: "table:nth-of-type(2) a[href^='http']"
        attr: href
      fifth:
        selector: "table:nth-of-type(3) a[href^='http']"
        attr: href
  # From 2018-04-30: div.corporate-<tier> boxes, then (2025) a table after each tier heading
  - kind: wiki
    api: https://osmfoundation.org/w/api.php
    title: Corporate_Members
    from: '20180430'
    levels:
      first:
        selector: "div.corporate-platinum a[href^='http'], h2#Platinum_Corporate_Members + table a[href^='http'], div.mw-heading:has(h2#Platinum_Corporate_Members) + table a[href^='http']"
      second:
        selector: "div.corporate-gold a[href^='http'], h2#Gold_Corporate_Members + table a[href^='http'], div.mw-heading:has(h2#Gold_Corporate_Members) + table a[href^='http']"
      third:
        selector: "div.corporate-silver a[href^='http'], h2#Silver_Corporate_Members + table a[href^='http'], div.mw-heading:has(h2#Silver_Corporate_Members) + table a[href^='http']"
      fourth:
        selector: "div.corporate-bronze a[href^='http'], h2#Bronze_Corporate_Members + table a[href^='http'], div.mw-heading:has(h2#Bronze_Corporate_Members) + table a[href^='http']"
      fifth:
        selector: "div.corporate-supporter a[href^='http'], h2#Supporter_Corporate_Members + table a[href^='http'], div.mw-heading:has(h2#Supporter_Corporate_Members) + table a[href^='http']"
normalize: 'true'
levels:
  first:
    name: Platinum
    amount: '30000'
    amountCurrency: EUR
    selector: "div.mw-heading:has(h2#Platinum_Corporate_Members) + table a[href^='http']"
    attr: href
    benefits:
      advisory: seat on advisory board; access to general meeting
      marketing: sponsorship recognition on social media
      logo: featured
  second:
    name: Gold
    amount: '15000'
    amountCurrency: EUR
    selector: "div.mw-heading:has(h2#Gold_Corporate_Members) + table a[href^='http']"
    attr: href
    benefits:
      advisory: seat on advisory board; access to general meeting
      marketing: sponsorship recognition on social media
      logo: yes
  third:
    name: Silver
    amount: '6000'
    amountCurrency: EUR
    selector: "div.mw-heading:has(h2#Silver_Corporate_Members) + table a[href^='http']"
    attr: href
    benefits:
      advisory: seat on advisory board; access to general meeting
      marketing: sponsorship recognition on social media
      logo: yes
  fourth:
    name: Bronze
    amount: '2250'
    amountCurrency: EUR
    selector: "div.mw-heading:has(h2#Bronze_Corporate_Members) + table a[href^='http']"
    attr: href
    benefits:
      advisory: seat on advisory board; access to general meeting
      logo: yes
  fifth:
    name: Supporter
    amount: '750'
    amountCurrency: EUR
    selector: "div.mw-heading:has(h2#Supporter_Corporate_Members) + table a[href^='http']"
    attr: href
    benefits:
      logo: text only
---
