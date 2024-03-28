---
title: "OpenAPI Documentation"
excerpt: "OpenAPI plans and concepts."
layout: default
permalink: /openapi
nav_order: 99
---

## OpenAPI Roadmap

We plan to use OpenAPI to provide read-only access to discover listed foundations, as well as get metadata for a foundation.

### Concept

- Foundation frontmatter metadata matches [openapi/.../foundation-schema.yaml](https://github.com/Punderthings/fossfoundation/blob/main/openapi/v1/foundation-schema.yaml)
- Find the list of foundations by identifier ([openapi](https://github.com/Punderthings/fossfoundation/blob/main/openapi/v1/openapi.yaml#L43)):
  - `GET https://raw.githubusercontent.com/Punderthings/fossfoundation/main/_foundations/list.json`
  - Returns `{"almalinux": ["almalinux.org","AlmaLinux","AlmaLinux OS Foundation"], "asf": ["apache.org", ...`
- Get data for a single foundation ([openapi](https://github.com/Punderthings/fossfoundation/blob/main/openapi/v1/openapi.yaml#L57)):
  - `GET https://raw.githubusercontent.com/Punderthings/fossfoundation/main/_foundations/asf.md`
  - Returns:

```YAML
---
identifier: asf
commonName: Apache Software Foundation
legalName: Apache Software Foundation
description:
contacturl:
website: https://www.apache.org/
foundingDate: '1999'
etc.
```

### TODOs

- Build update tooling based on schema to create the _foundations/list.json based on all foundation.md files checked in.
- Build PR linting actions based on that schema.
- Replicate for entities, sponsorships, etc.
- What else do we need to build tooling from to ensure data models are kept linted?
- What other read-only OpenAPI access should we provide?
