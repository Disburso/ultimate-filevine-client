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

### Changed
- Raised the Ruby floor to `>= 3.2` to use `Data.define` for value objects.
