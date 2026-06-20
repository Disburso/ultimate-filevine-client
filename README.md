# ultimate-filevine-client

[![CI](https://github.com/Disburso/ultimate-filevine-client/actions/workflows/ci.yml/badge.svg)](https://github.com/Disburso/ultimate-filevine-client/actions/workflows/ci.yml)

A thread-safe, multitenant-friendly Ruby client for the [Filevine v2 API](https://developer.filevine.io/docs/v2-us) (US environment first; CA/CJIS later).

Built for applications that talk to Filevine on behalf of **many tenants concurrently**: each tenant gets its own client instance with its own credentials and isolated token cache. There is intentionally **no global configuration**.

> **Status: in active development.** Auth, the gateway connection, pagination, the org-level resources (Projects / Contacts / Documents / Notes / Tasks / Project Types), the project-scoped sub-resources (`client.project(id).…`), and the full **billing** suite (`client.billing.…`) are implemented and tested. More resources (webhooks, custom fields) and a Redis-backed token store are planned. See `docs/openapi/API_SURFACE.md` for the full API surface.

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
| `client.projects` | `list`, `get`, `create`, `update`, `archive`, `remove_tag`, `add_hashtag`, `bulk_update_clients`, `conflict_check` | `/fv-app/v2/Projects` |
| `client.contacts` | `list`, `get`, `create`, `update`; sub-lists `addresses`, `emails`, `phones`, `projects`; `countries`, `primary_languages`, `remove_tag` | `/fv-app/v2/Contacts` |
| `client.documents` | `list`, `get`, `update`, `delete`; `search`, `recent`, `series`, `series_meta`; `copy`, `move`, `remove_tag`; `upload`, `download`; `create_upload_url`, `download_locator`, `batch_upload`, `confirm_upload`, `batch_download`, `add_revision`, `lock`, `unlock` | `/fv-app/v2/Documents` |
| `client.notes` | `list`, `get`, `create`, `update`, `move`, `remove_tag`, `pin`, `unpin` | `/fv-app/v2/Notes` |
| `client.tasks` | `list`, `get`, `create`, `update`, `assign`, `unassign`, `complete`, `uncomplete`, `snooze`, `pin`, `unpin` | `/fv-app/v2/tasks` |
| `client.project_types` | `list`, `get`, `sections`, `phases` | `/fv-app/v2/ProjectTypes` |
| `client.folders` | `list`, `get`, `create`, `update`, `delete`, `children`, `structure` | `/fv-app/v2/Folders` |
| `client.users` | `list`, `me`, `get`, `delete`, `tasks`, `appointments`, `projects_access`, `recent_projects` | `/fv-app/v2/Users` |
| `client.appointments` | `get`, `update`, `delete` | `/fv-app/v2/Appointments/{id}` |
| `client.comments` | `list`, `get`, `create`, `update` (note-scoped) | `/fv-app/v2/Notes/{noteId}/Comments` |
| `client.share_links` | `list`, `get`, `delete`, `delete_batch` | `/fv-app/v2/ShareLinks` |
| `client.reports` | `list`, `run` | `/fv-app/v2/Reports` |
| `client.custom_contacts` | `meta`, `create`, `update`, `tab` | `/fv-app/v2/Custom-Contacts` |
| `client.teams` | `list`, `get`, `create`, `add_members`, `remove_members`, `assign_member_roles`, `projects_access`, `add_project`, `remove_project`, `assign_to_projects` | `/fv-app/v2/teams` |
| `client.contact_types` | `list`, `create` | `/fv-app/v2/ContactTypes` |
| `client.deadline_chain_types` | `list` | `/fv-app/v2/chaintypes` |
| `client.images` | `get` (JSON envelope, or raw bytes with `as_json: false`) | `/fv-app/v2/images/{id}` |
| `client.vitals` | `get(project_id)` | `/fv-app/vitals` (org-level; distinct from `project(id).vitals`) |

```ruby
project = client.projects.get(88_123_456)
project.name              # => "Smith v. Acme"
project.client_name       # => "Jane Smith"
project["ProjectTypeCode"] # raw field access

client.projects.archive(88_123_456)                 # soft-delete (lowercase /projects path)
client.projects.add_hashtag("big-case", projects: [{ Native: 88_123_456 }])  # returns a Hashtag w/ counts
client.projects.remove_tag("urgent", project_ids: [{ Native: 1 }, { Native: 2 }]) # nil on full success, hash on 207
client.projects.bulk_update_clients([{ ProjectId: { Native: 1 }, PersonId: { Native: 9 } }])
client.projects.conflict_check(88_123_456, "Smith")  # raw results; NOT idempotent (persists a record)

client.contacts.create(FirstName: "Jane", LastName: "Smith")
client.contacts.phones(contact_id).each { |p| puts p.number }   # per-contact sub-list
client.contacts.projects(contact_id).first                       # ProjectContact memberships
client.notes.update(42, Body: "Updated note body")
client.documents.delete(7) # => true (raises on failure)
client.project_types.sections(4).each { |section| ... }

# Tasks have a full lifecycle (Filevine models a task as a note, so each call
# returns the updated task record):
task = client.tasks.create(Body: "Draft answer", ProjectId: { Native: 88_123_456 }, AssigneeId: { Native: 7 })
client.tasks.assign(task.id, 9)                        # reassign to another user
client.tasks.snooze(task.id, "2026-07-01T00:00:00Z")  # change the due date
client.tasks.complete(task.id, Hours: 0.5)            # optional time entry; omit to complete without one
client.tasks.unassign(task.id)                         # the spec's DELETE — returns the now-unassigned task
client.tasks.pin(task.id)                              # pin to the user's feed

client.folders.children(folder_id).each { |f| ... }   # page a folder's contents
client.folders.structure(project_id)                  # whole tree for a project
client.users.me                                       # the current API/service user
client.users.tasks(user_id).first                     # a user's task feed

client.comments.list(note_id).each { |c| ... }        # comments are note-scoped
client.comments.create(note_id, Body: "Looks good")
client.share_links.list.each { |link| ... }           # cursor-paged automatically
client.share_links.delete_batch(%w[key1 key2])
client.reports.run(report_id, limit: 100)             # raw, untyped result set

client.teams.list.each { |t| puts t.name }            # org teams (bare-array list)
client.teams.add_members(team_id, UserIDs: [5], AccessLevel: 1)
client.teams.add_project(team_id, project_id, apply_subscriptions: true)
# Custom contacts use a delta/field-bag write model:
client.custom_contacts.create(contact_id, [{ Action: "Add", Selector: "nickname", Value: "JJ" }])

# Move notes between projects / bulk-remove a tag (nil on full success, hash on a 207):
client.notes.move(note_ids: [{ Native: 5 }], source_project_id: { Native: 1 }, destination_project_id: { Native: 2 })
client.notes.remove_tag("urgent", note_ids: [{ Native: 5 }])

# Reference-data type lists:
client.contact_types.list.each { |t| puts "#{t.id} #{t.name}" }   # bare-int ids
client.contact_types.create("Expert Witness")
client.deadline_chain_types.list(name: "Discovery").first         # Identifier ids; lowercase /chaintypes
```

### Project-scoped sub-resources

`client.project(id)` returns a lightweight, immutable scope exposing the resources that live under a single project. (It's built fresh per call and is safe to share across threads.)

```ruby
scope = client.project(88_123_456)

scope.contacts.list                       # GET  /Projects/{id}/contacts
scope.contacts.add(OrgContactId: { Native: 5 }, Role: "Plaintiff")
scope.contacts.remove(project_contact_id)

scope.deadlines.create(Name: "Answer due", DueDate: "2026-07-01T00:00:00Z")
scope.deadlines.update(id, DoneDate: "2026-06-15T00:00:00Z")

scope.deadline_chains.list                # GET  /projects/{id}/deadlinechains
scope.deadline_chains.create(Name: "Discovery")   # POST /Projects/{id}/DeadlineChains (note casing)

scope.tasks.list                          # the project's task feed
scope.notes.list                          # the project's note feed
scope.notes.pin(note_id)
scope.team.list                           # TeamMember entities
scope.team.assign_roles(user_id, Roles: [{ OrgRoleId: { Native: 1 }, MakeFirst: true }])
scope.appointments.create(Title: "Depo", StartUtc: "...", EndUtc: "...", Attendees: [...])
scope.emails.add(From: { Address: "me@firm.com" }, To: [{ Address: "x@y.com" }], Subject: "Hi")
scope.documents.add(document_id, folder_id: 9)   # attach an existing org document

# Custom data: collection (sub-table) sections and static form sections, by selector
scope.collections("Damages").list
scope.collections("Damages").create(DataObject: { Amount: 5000 })
scope.forms("intake").update(DataObject: { ... })   # freeform → raw hash

scope.get                                 # the Project record itself
scope.vitals                              # raw vitals array
scope.archive                             # archive this project
scope.conflict_check("Smith")             # run a conflict check on this project
```

| Sub-resource | Methods | Notes |
|--------------|---------|-------|
| `.contacts` | `list`, `add`, `update`, `remove` | project↔contact links (`ProjectContact`) |
| `.deadlines` | `list`, `get`, `create`, `update`, `delete` | |
| `.deadline_chains` | `list`, `get`, `create`, `update`, `delete`, `update_chain_date` | create path is capitalized `/Projects/.../DeadlineChains` |
| `.tasks` | `list`, `pin`, `unpin` | project task feed |
| `.notes` | `list`, `pin`, `unpin` | project note feed |
| `.team` | `list`, `add`, `get`, `update`, `remove`, `assign_roles`, `teams`, `org_roles`, `org_role_positions` | |
| `.appointments` | `list`, `create`, `get`, `update`, `delete` | get/update/delete use the flat `/Appointments/{id}` path |
| `.emails` | `list`, `add`, `add_encoded` | emails are notes; `From` is required |
| `.documents` | `list`, `add` | `list` is the spec's deprecated per-project listing |
| `.collections(selector)` | `list`, `get`, `create`, `update`, `delete` | custom sub-table data (freeform `DataObject`) |
| `.forms(selector)` | `get`, `update` | static section data (raw hash) |
| `.invoices` | `list`, `get`, `create`, `update`, `delete`, `finalize` | billing — delegates to `client.billing.invoices` |
| `.billing_items` | `list`, `get`, `create`, `update` | billing — delegates to `client.billing.items` |
| `.funds` | `balance`, `list`, `get`, `create`, `void` | billing — delegates to `client.billing.funds` |
| `.transactions` | `list`, `create_payment`, `create_refund`, `update_payment`, `update_refund`, `void` | billing |
| `.billing_settings` | `get`, `update`, `vitals`, `fund_settings`, `update_fund_settings`, `client_matter_id`, `set_client_matter_id` | billing |

`client.project(id)` also exposes `.billing_vitals` (the project's billing vitals).

Filevine's paths are case-sensitive and inconsistently cased; each sub-resource uses the exact casing from the spec (so some hit `/Projects` and others `/projects` — that's intentional, not a typo).

### Uploading & downloading documents

Document bytes move through short-lived **presigned S3 URLs**: the gateway hands back a URL, and the file is transferred directly to/from S3 over a separate connection (no Filevine auth headers). The high-level helpers wrap the multi-step flow:

```ruby
# Upload: requests a URL, PUTs the bytes to S3, then commits to the project
# (without that commit the document stays pending and won't appear in listings).
locator = client.documents.upload(File.binread("complaint.pdf"),
                                  filename: "complaint.pdf", project_id: 88_123_456)
locator["DocumentId"]["Native"]   # the new document id

# Download: resolves the locator, then GETs the raw bytes
bytes = client.documents.download(document_id)
File.binwrite("out.pdf", bytes)
```

`upload` accepts a String of bytes or any object responding to `#read` (pass binary data). The lower-level steps are exposed too — `create_upload_url`, `download_locator`, `batch_upload` + `confirm_upload`, `batch_download`, `add_revision`, `lock` / `unlock` — for callers that need to drive the flow themselves. A failed S3 transfer raises `UltimateFilevineClient::TransferError` (the presigned signature is stripped from the message).

### Finding & organizing documents

```ruby
# Filename search within a project (searchTerm + projectId are required), auto-paged:
client.documents.search(search_term: "complaint", project_id: 88_123_456).each { |d| puts d.filename }
client.documents.recent(projectId: 88_123_456).first        # documents you recently opened
client.documents.series(projectId: 88_123_456).take(100)    # the doc series feed (cursor-paged)
client.documents.series_meta(projectId: 88_123_456)         # => { "Count", "MinDocId", "MaxDocId" }

# Bulk copy/move (DestinationFolderId required; pass DocumentIds and/or FolderIds).
# Returns a bulk-operation result — check Results[].Status (a 207 means partial failure):
client.documents.copy(DestinationFolderId: { Native: 12 }, DocumentIds: [{ Native: 3 }])
client.documents.move(DestinationFolderId: { Native: 12 }, FolderIds: [{ Native: 7 }])
client.documents.remove_tag("draft", document_ids: [{ Native: 3 }]) # nil on full success, hash on 207
```

## Billing

The billing suite hangs off a single facade, `client.billing`, which groups the billing sub-resources. Filevine's billing area is large and carries many `[Deprecated]` duplicates; this client implements the **current** endpoints only (the deprecated old/new pairs — e.g. `PUT /billing/invoices` — are intentionally omitted in favor of their replacements).

```ruby
# Invoices: list (org-wide or per project), then drive the lifecycle.
client.billing.invoices.list(project_id: 88_123_456, status: "Sent").each { |inv| puts inv.number }
invoice = client.billing.invoices.create(88_123_456, BillingItems: %w[item-guid-1 item-guid-2])
client.billing.invoices.finalize(88_123_456, invoice.id, tz_offset: -300)
client.billing.invoices.approve(invoice.id)
client.billing.invoices.mark_as_sent(invoice.id)

# Billing items (time / expense / flat fee):
item = client.billing.items.create(88_123_456, BillingType: "Time", IsBillable: true,
                                   IsChargeable: true, Date: "2026-07-01", Description: "Drafting", Quantity: 1.5)
client.billing.items.add_attachments(item.id, project_id: 88_123_456, doc_ids: [7])

# Payments & refunds (the "Transactions" family):
payment = client.billing.transactions.create_payment(88_123_456, Date: "2026-07-01", Total: 500, Method: "Check")
client.billing.transactions.apply_payment(invoice_id: invoice.id, transaction_id: payment.id, amount: 500)
client.billing.transactions.create_refund(88_123_456, Date: "2026-07-02", Total: 100, Method: "Check")

# Project trust funds, rate schedules, settings & vitals:
client.billing.funds.balance(88_123_456)
client.billing.funds.create(88_123_456, Amount: 1_000, FundType: 0)   # 0=Deposit
client.billing.rate_schedules.list.each { |r| puts r.name }
client.billing.settings.vitals(88_123_456)   # { "CurrentBalance", "InProgressBalance", "ProjectFundsBalance" }
```

| Accessor | Selected methods |
|----------|------------------|
| `client.billing.invoices` | `list(project_id:)`, `get`, `create`, `update`, `delete`, `finalize`, `pdf`, `update_description`, `update_status`, `void`, `write_off`, `approve`, `mark_as_sent`, `send_for_approval` |
| `client.billing.items` | `list(project_id:)`, `get`, `create`, `update`, `delete`, `set_note`, `remove_note`, `add_attachments`, `remove_attachments`, `accounting_sync` |
| `client.billing.transactions` | `list`, `get`, `create_payment`, `create_and_apply_payment`, `update_payment`, `create_refund`, `update_refund`, `void`, `unapply_payment`, `apply_payment` |
| `client.billing.funds` | `balance`, `list`, `get`, `create`, `void` |
| `client.billing.rate_schedules` | `list`, `get`, `create`, `update`, `delete`, `set_for_project`, `set_timekeeper`, `create_flat_fee_template`, `update_flat_fee_template`, `delete_flat_fee_template` |
| `client.billing.invoice_templates` | `list`, `get`, `create`, `update`, `delete`, `set_org_default`, `unset_org_default`, `project_default`, `set_project_default`, `unset_project_default` |
| `client.billing.codes` | `org`, `project`, `add_to_set` |
| `client.billing.settings` | `org`, `get`, `update`, `vitals`, `client_matter_id`, `set_client_matter_id`, `fund_settings`, `update_fund_settings` |
| `client.billing.fv_payments` | `invoice_payment_link`, `project_payment_link`, `account_mappings`, `available_account_mappings`, `project_account_mappings` |
| `client.billing.timekeeper_classifications` | `list` |

Invoices, billing items, transactions, project funds, rate schedules, and invoice templates return typed entities (`Entities::Invoice`, `BillingItem`, `Transaction`, `ProjectFund`, `RateSchedule`, `InvoiceTemplate`); settings, vitals, payment links, deposit-destination mappings, billing codes, and timekeeper classifications are configuration/reference blobs and come back as raw hashes/arrays. The project-centric resources are also reachable, project-id bound, via `client.project(id)` (`.invoices`, `.billing_items`, `.funds`, `.transactions`, `.billing_settings`, `.billing_vitals`).

As elsewhere, billing paths are taken verbatim from the spec — the casing is genuinely inconsistent across the family (e.g. transaction *reads* use capitalized `/Billing` while payment *writes* use lowercase `/billing`), so that is intentional, not a typo.

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
├── TransferError          (presigned S3 transfer failed; status, url, response_body)
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

### Recording against a sandbox org

Most specs assert against hand-authored fixtures, which verify the client matches Filevine's *documented* shapes. The recording pass (`spec/recording/`) closes the gap to *actual runtime* behavior: it drives a real **sandbox** org and records the interactions into VCR cassettes that CI then replays offline.

```sh
# 1. Put real sandbox creds in .env (FILEVINE_CLIENT_ID/SECRET/PAT, optionally
#    FILEVINE_ORG_ID/USER_ID to pin a specific org/user).
# 2. Record. FILEVINE_RECORD=1 records missing cassettes; =all re-records all.
FILEVINE_RECORD=1 bundle exec rake record:sandbox
# 3. Review the committed cassettes, then commit them. CI replays them offline.
bundle exec rspec --tag sandbox
```

What it records: a read-only pass (token mint → `user_orgs` bootstrap → `users.me`, `projects`, `project_types`) and a write lifecycle (create a contact + project, rename it, add a note and a task, complete/uncomplete the task, then **archive the project** to clean up). The synthetic client contact is left behind — the v2 API exposes no contact delete.

Safety:

- **Point it only at a sandbox org holding synthetic data.** Response bodies are committed verbatim. Credentials, bearer tokens, and the `x-fv-orgid`/`x-fv-userid` tenant ids are scrubbed automatically (`spec/support/vcr.rb`), but arbitrary body PII is **not** — that is what the synthetic-data requirement guards against.
- The default suite stays offline: without `FILEVINE_RECORD`, cassettes replay under dummy credentials (`record: :none`), and each recording example **skips** until its cassette exists, so `bundle exec rspec` is green before the first recording.
- Always review a freshly recorded cassette before committing it.

## License

Released under the [MIT License](LICENSE.txt).
