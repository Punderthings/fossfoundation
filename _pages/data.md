---
title: Data Philosophy
excerpt: Metadata standards and practices for the directory.
layout: default
permalink: /data
nav_order: 20
---

This foundation directory should curate metadata rigorously organized enough for academic research, and should be easy enough to maintain and use for any open source organizers who find it valuable

## Data Organization Philosophy 

Data is stored per foundation as a single `asf.md` file per organization in the `_foundations` directory.  Each file is a standard Jekyll document with a leading YAML frontmatter document with structured metadata, followed by a `---` YAML document separator, followed by unstructured Markdown content.

**Keep Updates Simple** Each foundation is a separate text-based document, making updates simple to make and review via GitHub PRs.

**Enough Structured Data** Metadata follows a simple schema, with a goal to be "good enough" for common research cases.  Researchers needing more structured data are welcome to collaborate and add new fields or features.

**Human Readable Formats** Using YAML and Markdown with GitHub Pages ensures the directory can be simple to understand for anyone, and can be a resource for anyone in open source who wants to learn about Foundations.

## Schemas And Validation

A simplistic [schema for foundation metadata](https://github.com/Punderthings/fossfoundation/blob/main/_data/foundations-schema.json) is checked in.  Suggestions for improvements to make the data more useful are appreciated!

The [roadmap](roadmap) includes building linting and data consistency checks.  Currently, these are done manually, or via using semi-automated ruby scripts in the `assets/ruby` directory.  For example:

```ruby
# If the schema changes, partially generate the Liquid to display foundations.html
assets/ruby/schema_utils.rb schema2liquid('_data/foundations-schema.json', ...)
# This generates the bulk of the page, but needs to be manually dropped in
```
