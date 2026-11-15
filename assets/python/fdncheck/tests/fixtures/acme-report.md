## fdncheck(acme)

fdncheck/0.1.0 checked 9 URLs for `acme` on 2026-11-15 (UTC): 3 to change, 4 to check, 1 could not be checked, 3 fine.

### Changes (verified by rule)

| Field | Was | Now | Rule |
| --- | --- | --- | --- |
| `website` | http://acme.example.org/ | https://acme.example.org/ | `redirect-permanent-same-site` (301 → 200) |
| `sponsorurl` | https://acme.example.org/sponsors#list | https://acme.example.org/supporters#list | `redirect-permanent-same-site` (308 → 200) |
| `conductProjects` | https://acme.example.org/old-coc | https://www.acme.example.org/code-of-conduct | `redirect-permanent-same-site` (301 → 200) |

### Please check (not changed)

- `sponsorships` missingmodel: no _sponsorships/missingmodel.md `unknown-reference`
- `donateurl` https://acme.example.org/donate: temporary redirect (302) to https://pay.example.net/acme; not changed (302 → 200) `redirect-temporary`
- `securityurl` https://acme.example.org/security: HTTP 404; not removed (404) `not-found`
- `conductProjects` https://acme.example.org/project-coc: permanent redirect (301) to another site: https://coc.example.net/ (301 → 200) `redirect-off-site`

### Could not check

- `conducturl` https://acme.example.org/coc: HTTP 403, probably blocking automated clients `blocked`

Foundation: acme · Checked-by: fdncheck/0.1.0 · Checked-on: 2026-11-15
