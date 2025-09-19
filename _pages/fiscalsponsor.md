---
title: Fiscal Sponsor/Agent Model
excerpt: Tracking Fiscal Sponsor or Agent arrangements
layout: default
permalink: /fiscalsponsor
parent: Data Models
nav_order: 60
---

Several foundations act as Fiscal Sponsors for multiple projects; accepting donations on behalf of projects hosted there, and managing the funds in some way.  The details of how the funds are controlled, and any fees charged, vary across the spectrum.  There may be cases of Fiscal Agents (where they are more an accountant, not a host) as well.

## Fiscal Sponsor or Agent Modeling

*Help Wanted* Modeling Fiscal Sponsor relationships, in terms of fee amounts, services offered and how paid, and governance policies is complex, since as a practical matter the governance or other ethos questions about a host will often be more important to FOSS communities.  Starting points could be:

- organization: the foundation offering hosting
  - TODO: should this data be part of the foundation model, or a separate table?
- agreementurl: link to descriptive homepage of sponsorship model
- agreementLegal: link to legal sponsorship agreement
- feeBase: base fee in %age of starting funds level
- feeDescription: brief description of how fees calculated
- servicesNotable: brief list of key services provided
- servicesurl: link to detailed services listing
- governanceFiscal: details of fiscal governance required
- governanceurl: link to any governance requirements/restrictions
- *other*: TODO analyze other quantifiable differences

## Roadmap / Contributions Wanted

*Help Wanted* both in completing this model, as well as researching various host organization actual policies.  

- [ ] Build fiscal sponsor model; fees, tax status, accounting details, services, etc.
- [ ] Data gathering and linting.
- [ ] Building visualizations showing differences.

## Research Notes

Review existing [list of foundation hosts](https://fossfoundation.info/categories#fiscalHost) for completness.

### Typical FOSS Code Hosts

- [Linux Foundation](https://fossfoundation.info/foundations/lf)
  - TBD
- [Eclipse Foundation](https://fossfoundation.info/foundations/eclipse) Working Groups
  - List of processes for WGs https://www.eclipse.org/org/working-groups/operations/ 
  - Membership prospectus https://www.eclipse.org/membership/documents/membership-prospectus.pdf
  - Working Groups vs. Collaborations https://www.eclipse.org/collaborations/
  - Services Offered https://www.eclipse.org/os4biz/services/
- [SFConservancy](https://fossfoundation.info/foundations/sfc)
  - agreementLegal: https://sfconservancy.org/static/docs/sponsorship-agreement-template.pdf
  - feeBase: 10%
  - restrictions: free software
  - governance: "Authority to manage the technical, artistic and philanthropic direction" is the project's governing body
  - servicesurl: https://sfconservancy.org/members/services/
  - applicationurl: https://sfconservancy.org/projects/apply/
- Open Collective
  - agreement overview: https://opencollective.com/pricing?tab=singleCollectiveWithoutAccount
- [Open Source Collective](https://fossfoundation.info/foundations/osc)
  - agreementLegal: https://docs.oscollective.org/welcome-and-introduction-to-osc/terms-of-fiscal-sponsorship
  - feeurl: https://docs.oscollective.org/welcome-and-introduction-to-osc/fees
  - feeBase: 10%
  - restrictions: https://docs.oscollective.org/interested-in-joining-osc/acceptance-criteria
  - servicesurl: https://docs.oscollective.org/welcome-and-introduction-to-osc/our-services-and-benefits
- [SPI, Inc.](https://fossfoundation.info/foundations/spi)
  - servicesurl: https://www.spi-inc.org/projects/services/
  - restrictions: https://www.spi-inc.org/projects/relationship/ free software
  - applyurl: https://www.spi-inc.org/projects/associated-project-howto/
- [NumFOCUS](https://fossfoundation.info/foundations/numfocus)
  - overview: https://numfocus.org/projects-overview offers fiscal sponsorship or just affiliation
  - feeBase: ?
  - restrictions: science focus, open governance, code of conduct
  - applicationurl: https://numfocus.org/wp-content/uploads/2024/05/NF-Sponsored-Project-Application-.pdf
- [Apache Software Foundation](https://fossfoundation.info/foundations/asf)
  - Targeted Sponsorships https://apache.org/foundation/sponsorship#targeted-sponsorship
- [Python Software Foundation](https://fossfoundation.info/foundations/python)
  - Grants Program https://www.python.org/psf/grants/

### Other Fiscal Hosts

- [Apereo](https://fossfoundation.info/foundations/apereo) - various kinds of membership (only a few hosted projects)
  - https://www.apereo.org/join-us/foundation-members
  - https://www.apereo.org/join-us/community-members
  - https://www.apereo.org/join-us/institutional-members
  - https://www.apereo.org/join-us/sustaining-members
  - https://www.apereo.org/join-us/commercial-members
  - https://apereo.cloud.xwiki.com/xwiki/bin/view/Apereo%20Foundation/Finance/Fiscal%20Sponsorship/
