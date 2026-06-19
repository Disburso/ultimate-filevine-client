# frozen_string_literal: true

source "https://rubygems.org"

# Runtime dependencies are declared in the gemspec.
gemspec

group :development, :test do
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.13"
  gem "rubocop", "~> 1.60", require: false
  gem "rubocop-rspec", "~> 3.0", require: false
  gem "vcr", "~> 6.2"
  gem "webmock", "~> 3.23"
end

group :development do
  # Optional collaborators the gem can use but does not hard-depend on
  # (a thread-safe persistent Faraday adapter; a Redis-backed token store).
  gem "faraday-net_http_persistent", "~> 2.1", require: false
  gem "redis", "~> 5.0", require: false
end
