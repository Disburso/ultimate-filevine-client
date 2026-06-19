# frozen_string_literal: true

require_relative "lib/ultimate_filevine_client/version"

Gem::Specification.new do |spec|
  spec.name = "ultimate-filevine-client"
  spec.version = UltimateFilevineClient::VERSION
  spec.authors = ["Andriy Tyurnikov"]
  spec.email = ["Andriy.Tyurnikov@gmail.com"]

  spec.summary = "Thread-safe, multitenant Ruby client for the Filevine v2 API"
  spec.description = "A Ruby client for the Filevine v2 (US) API. Built for concurrent, multitenant " \
                     "applications: per-tenant credentials and client instances, pluggable token " \
                     "storage, single-flight token refresh, and auto-pagination."
  spec.homepage = "https://github.com/swareco/ultimate-filevine-client"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # The require path is `ultimate_filevine_client` even though the gem name is
  # dasherized: `require "ultimate_filevine_client"`.
  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE.txt", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "concurrent-ruby", "~> 1.2"
  spec.add_dependency "faraday", "~> 2.9"
  spec.add_dependency "faraday-retry", "~> 2.2"
end
