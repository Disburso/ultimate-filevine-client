# ultimate-filevine-client

A thread-safe, multitenant-friendly Ruby client for the [Filevine v2 API](https://developer.filevine.io/docs/v2-us) (US environment first; CA/CJIS later).

Built for applications that talk to Filevine on behalf of **many tenants concurrently**: each tenant gets its own client instance with its own credentials and isolated token cache. There is intentionally **no global configuration**.

> **Status: in active development.** Auth, the gateway connection, pagination, and the Projects / Contacts / Documents / Notes / Tasks / Project Types resources are implemented and tested. More resources and a Redis-backed token store are planned. See `docs/openapi/API_SURFACE.md` for the full API surface.

## Installation

```ruby
# Gemfile
gem "ultimate-filevine-client"
```

```ruby
require "ultimate_filevine_client" # note: underscores, not dashes
```

Requires Ruby >= 3.2.

## Quick start

```ruby
config = UltimateFilevineClient::Configuration.new(
  client_id:     ENV.fetch("FILEVINE_CLIENT_ID"),
  client_secret: ENV.fetch("FILEVINE_CLIENT_SECRET"),
  pat:           ENV.fetch("FILEVINE_PAT"),
  region:        :us
)

client = UltimateFilevineClient::Client.new(config: config)

client.projects.list(limit: 50).each do |project|
  puts "#{project.id}  #{project.name}  (#{project.phase})"
end
```

## Authentication

The gem uses the Filevine **gateway (Personal Access Token)** flow. You supply an OAuth `client_id` / `client_secret` plus a `pat`; the client mints a short-lived bearer token from `https://identity.filevine.com/connect/token` and refreshes it automatically (the gateway flow has no refresh token, so "refresh" re-mints from the PAT).

Most gateway requests also require an org id and user id, sent as `x-fv-orgid` / `x-fv-userid` headers. If you don't know them yet, bootstrap them:

```ruby
payload = client.user_orgs            # POST /fv-app/v2/utils/GetUserOrgsWithToken
org_id  = payload.dig("Orgs", 0, "OrgId")
user_id = payload.dig("User", "UserId")

# Configuration is immutable; derive a new client with the resolved ids:
scoped = UltimateFilevineClient::Client.new(config: config.with(org_id:, user_id:))
scoped.projects.list.first
```

## Multitenancy & concurrency

- **One client per tenant.** Build a `Client` from each tenant's `Configuration`. Two clients share no credential or token state.
- **Thread-safe.** `Configuration` is frozen; the token cache is thread-safe; token refresh is single-flight (one mint even under many concurrent callers). A `Client` and its resources/paginators are safe to use from multiple threads.
- **Per-tenant rate limiting.** Retry/backoff state lives on each tenant's connection, so one tenant hitting a 429 never throttles another.

## Configuration options

`UltimateFilevineClient::Configuration.new(...)`:

| Option | Default | Notes |
|--------|---------|-------|
| `client_id:` | — (required) | OAuth client id |
| `client_secret:` | — (required) | OAuth client secret |
| `pat:` | — (required) | Personal Access Token |
| `region:` | `:us` | `:us` only for now (`:ca`/`:cjis` raise until hosts are confirmed) |
| `org_id:` / `user_id:` | `nil` | sent as `x-fv-orgid` / `x-fv-userid`; resolve via `#user_orgs` |
| `scope:` | gateway default | OAuth scope string |
| `token_store:` | `MemoryStore.new` | pluggable token cache (see below) |
| `adapter:` | `Faraday.default_adapter` | Faraday adapter |
| `open_timeout:` / `timeout:` | `10` / `30` | seconds |
| `token_expiry_skew:` | `60` | re-mint this many seconds before expiry |
| `max_retries:` | `2` | retries for idempotent 429/5xx |
| `retry_interval:` | `0.5` | base backoff (seconds); honors `Retry-After` |

## Token storage

By default tokens live in a process-local, thread-safe `MemoryStore`. To share a tenant's token across processes/workers, inject any object implementing the `TokenStore::Base` contract (`read`, `write`, `delete`), keyed per tenant:

```ruby
class MyRedisTokenStore < UltimateFilevineClient::TokenStore::Base
  def initialize(redis) = @redis = redis
  def read(key)
    raw = @redis.get(key) or return nil
    data = JSON.parse(raw)
    UltimateFilevineClient::Auth::Token.new(value: data["value"], expires_at: Time.at(data["expires_at"]))
  end
  def write(key, token)
    ttl = (token.expires_at - Time.now).to_i
    @redis.set(key, { value: token.value, expires_at: token.expires_at.to_i }.to_json, ex: [ttl, 1].max)
    token
  end
  def delete(key) = @redis.del(key)
end

config = UltimateFilevineClient::Configuration.new(..., token_store: MyRedisTokenStore.new(redis))
```

## Resources

Each resource hangs off the client and returns entity objects (raw payload always available via `[]` / `to_h`).

| Accessor | Methods | Path |
|----------|---------|------|
| `client.projects` | `list`, `get`, `create`, `update` | `/fv-app/v2/Projects` |
| `client.contacts` | `list`, `get`, `create`, `update` | `/fv-app/v2/Contacts` |
| `client.documents` | `list`, `get`, `update`, `delete` | `/fv-app/v2/Documents` |
| `client.notes` | `list`, `get`, `create`, `update` | `/fv-app/v2/Notes` |
| `client.tasks` | `list`, `get` | `/fv-app/v2/tasks` |
| `client.project_types` | `list`, `get`, `sections` | `/fv-app/v2/ProjectTypes` |

```ruby
project = client.projects.get(88_123_456)
project.name              # => "Smith v. Acme"
project.client_name       # => "Jane Smith"
project["ProjectTypeCode"] # raw field access

client.contacts.create(FirstName: "Jane", LastName: "Smith")
client.notes.update(42, Body: "Updated note body")
client.documents.delete(7) # => true (raises on failure)
client.project_types.sections(4).each { |section| ... }
```

## Pagination

`#list` returns a lazy, auto-paging collection (offset/limit under the hood). Pages are fetched only as you consume them:

```ruby
client.projects.list.each { |p| ... }     # walks every page
client.projects.list.first                # fetches one page only
client.projects.list(limit: 25).take(10)  # stops after 10 records
client.projects.list.lazy.select { |p| !p.archived? }.first(5)

# Pass filter/query params straight through:
client.projects.list(requestedFields: "ProjectName,ClientName")
```

Each iteration runs an independent cursor, so a list is safe to reuse and to iterate from multiple threads.

## Errors

Non-2xx responses raise a typed exception; rescue `UltimateFilevineClient::Error` to catch everything.

```
Error
├── ConfigurationError
├── AuthenticationError
├── TimeoutError
└── RequestError            (status, response_headers, response_body)
    ├── ClientError         (4xx)
    │   ├── BadRequest (400)  Unauthorized (401)  Forbidden (403)
    │   ├── NotFound (404)    Conflict (409)      UnprocessableEntity (422)
    │   └── RateLimitError (429)  # exposes #retry_after
    └── ServerError         (5xx)
```

```ruby
begin
  client.projects.get(does_not_exist)
rescue UltimateFilevineClient::NotFound => e
  warn "No such project (HTTP #{e.status})"
rescue UltimateFilevineClient::RateLimitError => e
  sleep e.retry_after.to_i
  retry
end
```

Idempotent 429/5xx responses are retried automatically (honoring `Retry-After`); a `401` transparently re-mints the token and retries once.

## Development

```sh
bin/setup            # bundle install
bundle exec rake     # runs rspec + rubocop
bin/console          # IRB with the gem loaded
```

Tests stub all HTTP via WebMock/VCR and never reach the live Filevine API. The committed OpenAPI specs under `docs/openapi/` are the source of truth; regenerate the API-surface reference with `python3 scripts/extract_api_surface.py`.

## License

Released under the [MIT License](LICENSE.txt).
