# Repository Guidelines

`ultimate-filevine-client` is a Ruby gem providing a client for the Filevine API.

## Product Requirements Source
- The authoritative source for product requirements and API behavior is the Filevine developer documentation at https://developer.filevine.io/. Entry/landing page: https://developer.filevine.io/docs/v2/07b0338388c49-filevine-api-dynamic-documentation-links.
- Docs are region/cell-based. The **US environment is the first/primary target**; other regions come later:
  - US (primary target): https://developer.filevine.io/docs/v2-us
  - Canada (future): https://developer.filevine.io/docs/v2-ca
  - CJIS / government (future): https://developer.filevine.io/docs/v2-cjis
- Model endpoints, request/response shapes, authentication, and pagination after the v2 API as documented there. When behavior is ambiguous, defer to the published spec over assumptions.
- The docs are a client-rendered Stoplight app (workspace `filevine`, project `v2-us`), so the spec is not available via a plain HTTP GET of the page HTML. To read it programmatically, render the page (e.g., a headless browser) or obtain the OpenAPI export from Stoplight rather than scraping the served HTML.

## Project Structure & Module Organization
- `lib/` holds the gem source. Namespace everything under `lib/ultimate_filevine_client/` and expose the public entrypoint in `lib/ultimate_filevine_client.rb`.
- `spec/` mirrors `lib/` for RSpec tests (e.g., `lib/.../client.rb` → `spec/.../client_spec.rb`).
- `spec/spec_helper.rb` and `spec/support/` contain shared test configuration and helpers.
- `bin/` holds executables (`bin/console`, `bin/setup`); `*.gemspec` defines metadata and dependencies.

## Build, Test, and Development Commands
- `bundle install` — install dependencies from the `Gemfile` and gemspec.
- `bundle exec rspec` — run the full test suite.
- `bundle exec rspec spec/path/to/file_spec.rb` — run a single spec file.
- `bundle exec rubocop` — lint and check style.
- `bundle exec rubocop -a` — auto-correct safe offenses.
- `bin/console` — open an IRB session with the gem loaded for manual exploration.
- `rake build` / `rake release` — build and publish the gem.

## Coding Style & Naming Conventions
- Use two-space indentation; no tabs. Keep lines reasonably short (RuboCop default ~120 chars).
- `snake_case` for methods, variables, and files; `CamelCase` for classes and modules; `SCREAMING_SNAKE_CASE` for constants.
- One class/module per file, with the file path matching the namespace.
- Add `# frozen_string_literal: true` at the top of every Ruby file.
- Prefer keyword arguments for public methods and small, focused objects.

## Testing Guidelines
- Use RSpec. Name files `*_spec.rb` and place them under `spec/` mirroring `lib/`.
- Write `describe` blocks per class/method and `context` blocks per scenario.
- Stub external HTTP calls (e.g., with WebMock or VCR); never hit the live Filevine API in tests.
- Run `bundle exec rspec` before pushing; keep new code covered.

## Commit & Pull Request Guidelines
- Write imperative, present-tense commit subjects (e.g., "Add session auth helper"); keep them under ~72 characters.
- Keep commits focused; explain the "why" in the body when non-obvious.
- PRs should include a clear description, linked issues, and notes on testing. Ensure `rspec` and `rubocop` pass before requesting review.

## Security & Configuration Tips
- Never commit API keys or Filevine credentials. Load secrets from environment variables (e.g., `ENV["FILEVINE_API_KEY"]`).
- Keep sample credentials in `.env.example` and add `.env` to `.gitignore`.
