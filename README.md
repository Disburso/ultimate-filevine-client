# ultimate-filevine-client

A thread-safe, multitenant-friendly Ruby client for the [Filevine v2 API](https://developer.filevine.io/docs/v2-us) (US environment first; CA/CJIS later).

> **Status: early scaffold.** The HTTP client, auth, resources, and pagination are being built out. See `docs/openapi/API_SURFACE.md` for the extracted API surface and `AGENTS.md` for contributor conventions.

## Design goals

- **Per-tenant clients, no global state.** Construct one client per tenant with that tenant's own credentials — there is intentionally no `UltimateFilevineClient.configure`. Two tenants never share credential or token state.
- **Concurrency-safe.** Immutable configuration, isolated per-tenant token caches, single-flight (race-free) token refresh, and a thread-safe HTTP connection.
- **Pluggable token storage.** Default thread-safe in-memory store; an optional Redis-backed store lets tokens be reused across processes/workers, keyed per tenant.

## Installation

```ruby
# Gemfile
gem "ultimate-filevine-client"
```

```ruby
require "ultimate_filevine_client" # note: underscores, not dashes
```

## Usage (target API — under construction)

```ruby
config = UltimateFilevineClient::Configuration.new(
  client_id:     ENV.fetch("FILEVINE_CLIENT_ID"),
  client_secret: ENV.fetch("FILEVINE_CLIENT_SECRET"),
  pat:           ENV.fetch("FILEVINE_PAT"),
  region:        :us
)

client = UltimateFilevineClient::Client.new(config: config)
client.projects.list(limit: 50)
```

## Development

```sh
bin/setup            # bundle install
bundle exec rake     # runs rspec + rubocop
bin/console          # IRB with the gem loaded
```

Tests stub all HTTP via WebMock/VCR and never reach the live Filevine API.

## License

Released under the [MIT License](LICENSE.txt).
