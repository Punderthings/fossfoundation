---
identifier: openmainframe
commonName: Open Mainframe Foundation
fiscalHost: lf
nonprofit: lf
sponsorurl: https://raw.githubusercontent.com/openmainframeproject/omp-landscape/main/landscape.yml
levelurl: https://openmainframeproject.org/about/join/
landscape: Open Mainframe Project Member Company
# Historical sponsor lists; see assets/ruby/sponsor_archive.rb
sources:
  - kind: git
    repo: https://github.com/openmainframeproject/omp-landscape
    path: landscape.yml
levels:
  first:
    name: Platinum
    value: '50000'
    selector: ''
    attr: homepage_url
    benefits:
      governance: appoint board seat
  second:
    name: Silver
    value: '20000'
    amountvaries: sliding scale by number employees
    selector: ''
    attr: homepage_url
    benefits:
      governance: vote for board seat
      logo: 'yes'
  academic:
    name: Academic Institution
    value: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
  community:
    name: Associate
    value: '0'
    selector: ''
    attr: homepage_url
    benefits:
      logo: 'yes'
---
