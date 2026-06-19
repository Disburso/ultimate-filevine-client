# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/support/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Never reach the live Filevine API: cassettes must already exist. Override
  # per-example with `vcr: { record: :once }` when first recording.
  config.default_cassette_options = { record: :none }

  # Keep tenant secrets out of committed cassettes.
  %w[FILEVINE_CLIENT_SECRET FILEVINE_PAT].each do |key|
    config.filter_sensitive_data("<#{key}>") { ENV.fetch(key, nil) }
  end

  config.filter_sensitive_data("<BEARER_TOKEN>") do |interaction|
    authorization = interaction.request.headers["Authorization"]&.first
    authorization.split.last if authorization&.start_with?("Bearer ")
  end
end
