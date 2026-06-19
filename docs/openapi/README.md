# Filevine OpenAPI specs — spec of record

These are the authoritative Filevine v2 API specifications, exported from the official
Stoplight documentation. **Build resource code against these files**, not against the
docs web pages — those are a client-rendered Stoplight app and a plain HTTP GET returns
only a JS shell.

## Files

| File | Spec | Host | Notes |
|------|------|------|-------|
| `FV.App.API.json` | Swagger 2.0 | `api.filevineapp.com` | "Filevine Api Gateway" v2.0.0 — 222 paths under `/fv-app/v2/...`. Projects, contacts, documents, billing, webhooks, etc. |
| `FV.Identity.API.json` | OpenAPI 3.0.1 | `identity.filevine.com` | "Filevine Identity API" — `/connect/token` (mint a PAT bearer token) and `/identity/user`. |

> Note the **US gateway host is `api.filevineapp.com`** (not `api.filevine.io`, which is the
> legacy v1 session base). The identity/token host is `identity.filevine.com`.

## Provenance

- Stoplight project: `cHJqOjI0MjAxOA` (base64 of `prj:242018`, "Filevine API Gateway"),
  workspace `filevine`, project `v2-us`.
- Fetched 2026-06-20 from:
  - `https://api.stoplight.io/projects/cHJqOjI0MjAxOA/branches/main/export/reference/FV.App.API.json`
  - `https://api.stoplight.io/projects/cHJqOjI0MjAxOA/branches/main/export/reference/FV.Identity.API.json`

## Refreshing

Re-fetch with the same two URLs and diff to spot API changes:

```sh
curl -sSL -o docs/openapi/FV.App.API.json \
  https://api.stoplight.io/projects/cHJqOjI0MjAxOA/branches/main/export/reference/FV.App.API.json
curl -sSL -o docs/openapi/FV.Identity.API.json \
  https://api.stoplight.io/projects/cHJqOjI0MjAxOA/branches/main/export/reference/FV.Identity.API.json
```

Files are stored as exported (raw bytes from Stoplight) so a re-fetch diffs cleanly.
