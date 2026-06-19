# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial gem scaffold: gemspec, Bundler `Gemfile`, `Rakefile` (`spec` + `rubocop`),
  RSpec with WebMock/VCR, RuboCop config, `bin/console` + `bin/setup`, `.env.example`.
- Committed Filevine v2 OpenAPI specs (`docs/openapi/`) and an extracted API-surface
  reference with its generator (`scripts/extract_api_surface.py`).
- Auth/concurrency core for multitenant use:
  - `Region` resolver (US gateway/identity hosts; CA/CJIS raise until confirmed).
  - Immutable `Auth::Credentials` (validated, secret-redacting) and `Auth::Token`
    (absolute expiry with a refresh skew).
  - `TokenStore::Base` interface and a thread-safe `TokenStore::MemoryStore`
    (Concurrent::Map), keyed per tenant.
  - Frozen, per-tenant `Configuration` (no global state) with a `token_key`.
  - `Auth::Authenticator` — single-flight, race-free token minting via the
    gateway PAT grant (`POST /connect/token`), with double-checked locking.
  - Per-tenant `Client` exposing `#access_token`.
  - Concurrency spec proving exactly one mint under 20 simultaneous threads.
- Gateway HTTP + error layer:
  - HTTP error hierarchy (`RequestError` → `ClientError`/`ServerError` and
    `BadRequest`/`Unauthorized`/`Forbidden`/`NotFound`/`Conflict`/
    `UnprocessableEntity`/`RateLimitError`), plus `TimeoutError`, mapped from
    status via `UltimateFilevineClient.error_class_for`.
  - `Response` value object and a `Connection` that injects `Authorization` +
    `x-fv-orgid` + `x-fv-userid` on every request, retries idempotent 429/5xx
    (honoring Retry-After), maps error statuses to exceptions, and re-mints the
    token once on a 401.
  - `Client` now exposes a per-tenant `#connection`, low-level verb helpers, and
    a `#user_orgs` bootstrap (`POST /fv-app/v2/utils/GetUserOrgsWithToken`).
  - `Configuration#with` for immutable updates (e.g. populating org_id/user_id
    after bootstrap); token cache key corrected to depend on credentials only.

### Changed
- Raised the Ruby floor to `>= 3.2` to use `Data.define` for value objects.
