---
title: "OpenAPI Documentation"
excerpt: "OpenAPI plans and concepts."
layout: default
permalink: /openapi
nav_order: 99
---

## OpenAPI Roadmap

**DRAFT** What do contributors think about using OpenAPI to define metadata schemas, and to define a simple set of get-type operations to allow programmatic reading of various metadata stores?

See [mocked-up OpenAPI (incomplete!) sample](https://github.com/Punderthings/fossfoundation/blob/main/openapi/v1/openapi.yaml) and please comment.

### Concept

- Build full OpenAPI schema for the Foundation organizational model - essentially defining all the yaml frontmatter data in the _foundation/*.md files.
- Build update tooling based on schema to create the _foundations/list.json based on all foundation.md files checked in.
- Build PR linting actions based on that schema.
- Replicate for entities, sponsorships, etc.
- What else do we need to build tooling from to ensure data models are kept linted?
- What other read-only OpenAPI access should we provide?
