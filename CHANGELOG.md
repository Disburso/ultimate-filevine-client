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
- Resource + pagination layer:
  - `Pagination::Paginator` — lazy, auto-paging `Enumerable` over offset/limit
    (`Items`/`HasMore`), fetching pages only as consumed; independent cursor per
    `#each`, safe to iterate concurrently.
  - `Entities::Base` + `Entities::Project` — read-only wrappers exposing named
    fields (`id` unwraps the `ProjectId` Identifier), with raw `[]`/`to_h`.
  - `Resources::Base` + `Resources::Projects` (`#list`/`#get`/`#create`/`#update`
    against `/fv-app/v2/Projects`), and `Client#projects`.
  - VCR-backed end-to-end spec: mint a token then auto-page projects from a
    committed cassette (`spec/support/cassettes/projects_list.yml`).
- More resources, each with an entity and specs:
  - `Contacts` (list/get/create/update), `Documents` (list/get/update/delete),
    `Notes` (list/get/create/update), `Tasks` (list/get, lowercase `/tasks`
    path), `ProjectTypes` (list/get + auto-paging `#sections`).
  - Shared `Resources::Base` helpers (`list_entities`/`fetch_entity`/
    `create_entity`/`update_entity`) and entity classes
    (`Contact`/`Document`/`Note`/`Task`/`ProjectType`).
  - `Client` now wires all resource accessors from a `RESOURCES` registry,
    built eagerly to avoid lazy-memo races.
- Comprehensive README: quick start, auth + bootstrap, multitenancy/concurrency,
  configuration options, pluggable token storage, resources, pagination, and the
  error hierarchy.
- Project-scoped sub-resources via `client.project(id)` (a lightweight, immutable,
  thread-safe `ProjectScope`):
  - `contacts`, `deadlines`, `deadline_chains`, `tasks`, `notes`, `team`,
    `appointments`, `emails`, `documents`, plus selector-based `collections(sel)`
    and `forms(sel)`, and `get` / `vitals` / `add_guest_user` /
    `toggle_section_visibility`.
  - New entities: `ProjectContact`, `Deadline`, `DeadlineChain`, `TeamMember`,
    `Appointment`, `CollectionItem` (Tasks/Notes/Documents reuse existing ones).
  - Paths are taken verbatim from the spec, preserving its case-sensitive,
    inconsistent casing (e.g. `/Projects/.../DeadlineChains` on create vs
    `/projects/.../deadlinechains` elsewhere; the flat `/Appointments/{id}` for
    single-appointment ops). Grounded against `docs/openapi/FV.App.API.json`.
  - `Resources::Base` gained shared `post_entity` / `put_entity` / `delete_path`
    helpers; `Resources::ProjectScoped` carries the project id for sub-resources.
- Org-level `Folders` and `Users` resources:
  - `client.folders` — `list` / `get` / `create` / `update` / `delete`, plus
    `children` (page one folder) and `structure(project_id)` (whole tree); new
    `Entities::Folder`.
  - `client.users` — `list` / `me` / `get` / `delete`, plus auto-paging `tasks`,
    `appointments`, `projects_access`, and `recent_projects` (a bare,
    non-paginated array); new `Entities::User` (wraps the OrgUser record).
  - Casing taken verbatim from the spec: `/Users` and `/Users/Me` are
    capitalized while per-user reads use lowercase `/users/{id}`; folders are
    capitalized with a lowercase `/Folders/list` structure endpoint.
- Standalone org-level `Appointments`, `Comments`, `Share Links`, and `Reports`
  resources:
  - `client.appointments` — `get` / `update` / `delete` an appointment by id on
    the flat `/Appointments/{id}` path (list/create stay project-scoped).
  - `client.comments` — note-scoped `list` / `get` / `create` / `update` under
    `/Notes/{noteId}/Comments`; new `Entities::Comment`.
  - `client.share_links` — `list` (keyset/cursor paged), `get`, `delete`, and
    `delete_batch` (bare-array body); new `Entities::ShareLink` (string-keyed).
  - `client.reports` — `list` saved reports + `run` (returns the raw, untyped
    result set); new `Entities::Report`.
  - Added `Pagination::CursorPaginator` for keyset endpoints whose response
    nests records under a custom key and advances via an opaque cursor (Share
    Links: records under `ShareLinks`, `NewLastKey` -> `lastKey`), exposed via a
    `Resources::Base#cursor_paginate` helper.
- Contact sub-lists and reference data on `client.contacts`:
  - Auto-paging `addresses`, `emails` (lowercase `emailaddresses` path),
    `phones`, and `projects` (ProjectContact memberships); new `Entities::Address`,
    `Entities::Email`, `Entities::Phone` (projects reuse `Entities::ProjectContact`).
  - `countries` (code => name map) and `primary_languages` (string array) raw
    reference lists, and `remove_tag(tag_name, person_ids:)` (a DELETE with a
    body) for bulk tag removal.
- Custom Contacts (`client.custom_contacts`) and org-level Teams (`client.teams`):
  - `custom_contacts` — `meta`, `create`, `update` (delta/field-bag `requests`
    array body; both return a `Contact`), and `tab` (freeform custom-data hash).
  - `teams` — `list` (bare array of `Entities::Team`), `get`, `create`, plus the
    action writes `add_members`, `remove_members`, `assign_member_roles`,
    `add_project`, `remove_project`, `assign_to_projects`, and auto-paging
    `projects_access`. New `Entities::Team`.
  - Added a `Resources::Base#perform_action` helper for 204/no-content writes;
    `delete_path`, `delete_batch`, and `remove_tag` now route through it.
- Documents-family extras on `client.documents` beyond CRUD + byte transfer:
  - `search` (filename search within a project; `searchTerm` + `projectId`
    required) and `recent` (recently-opened) — both auto-paging `Document`s.
  - `series` (the document series feed) — cursor-paged via the `CursorPaginator`
    (response `LastID` carried back as the next `lastId`) — and `series_meta`,
    the raw `{ Count, MinDocId, MaxDocId }` bootstrap counts.
  - `copy` / `move` (bulk folder operations; `DestinationFolderId` + `DocumentIds`
    and/or `FolderIds`) returning the raw multi-status result (copy is `201`, move
    `200`, either may `207`), and `remove_tag` (bulk tag removal; `nil` on `204`
    or the multi-status hash on `207`, mirroring `projects.remove_tag`).
  - `Entities::Document` gained `folder_name`, `uploader_id`, `upload_date`,
    `current_version`, and `hashtags`.
- Projects-family extras on `client.projects` beyond core CRUD:
  - `archive` (the spec's lowercase `DELETE /projects/{projectid}` — a soft
    delete), `remove_tag` (bulk tag removal; returns `nil` on full success or the
    multi-status hash on a `207`), `add_hashtag` (applies a hashtag to
    projects/docs/notes/comments, returning a new `Entities::Hashtag` with usage
    counts), `bulk_update_clients` (`PUT /projects/bulk`), and `conflict_check`
    (`POST /Utils/conflictcheck/...` with a `searchTerm` query — not idempotent).
  - `ProjectScope` gained `archive` and `conflict_check(search_term)` delegators.
  - Paths preserve the family's inconsistent casing verbatim (capital `/Projects`
    for tag removal, capital `/Utils`, lowercase `/projects` for archive/bulk).
- Full Task CRUD + lifecycle on `client.tasks` (previously read-only):
  - `create`, `update` (body only), and `unassign` — the spec's `DELETE` on a
    task, which returns the now-unassigned task rather than no content.
  - `assign(task_id, assignee_id)` (a body-less `PATCH`), `complete` (with an
    optional time-entry body) / `uncomplete`, `snooze(task_id, date)` (a `PUT`
    carrying the single PascalCase `SnoozeDate` field), and feed `pin` / `unpin`.
  - `Entities::Task` gained `project_id`, `assignee_id`, `target_date`,
    `pinned_to_feed?`, and `pinned_to_project?` to surface the lifecycle fields.
  - `Resources::Base` gained `delete_entity` (a `DELETE` that returns a record),
    and `update_entity` now allows a body-less `PATCH` (for `assign`). Paths are
    taken verbatim from the spec, preserving its inconsistent casing (capital
    `{taskID}` on complete/uncomplete, `{assigneeID}` on assign).
- Document upload/download via the presigned-URL (S3) flow:
  - `client.documents.upload(io, filename:, project_id:, ...)` requests an upload
    URL, PUTs the bytes to S3, and commits via Add Document to Project;
    `client.documents.download(id)` resolves the locator and GETs the bytes.
  - Lower-level steps: `create_upload_url`, `download_locator`, `batch_upload`,
    `confirm_upload`, `batch_download`, `add_revision`, `lock`, `unlock`.
  - New `Transfer` helper performs raw byte transfers to absolute presigned URLs
    over a separate connection (no gateway base URL, no auth headers, no JSON
    middleware). New `TransferError` (strips the URL signature from its message).

### Changed
- Raised the Ruby floor to `>= 3.2` to use `Data.define` for value objects.
