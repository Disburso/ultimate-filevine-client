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
