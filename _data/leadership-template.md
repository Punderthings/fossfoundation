---
identifier: # Foundation id; must match the _foundations/<identifier>.md filename
commonName: # Common name of the foundation
asOf: # Date this roster was last verified against source (YYYY-MM-DD)
sources: # List of official URLs verified against; each with url, type, retrieved
people: # List of governing people; per-person fields are in leadership-schema.json
---

LEADERSHIP_TEMPLATE To add a leadership roster, copy this file to _leadership/<identifier>.md using the same identifier as the foundation's _foundations record.  Fill the people list with board directors, officers, and paid staff you can verify against official sources (from that foundation, not wikipedia or the like).  Never guess: leave a field null and note it in the body if unknown.  Every person carries a sourceUrl and a confidence; use 1.0 only for facts stated verbatim.  Field descriptions are in the leadership-schema.json file.  Then replace this section (the content of the Jekyll document) with a short factual note on scope, provenance, and any gaps.  Submit a PR with this new identifier.md file in the _leadership directory.
