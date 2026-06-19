# frozen_string_literal: true

require_relative "ultimate_filevine_client/version"

# Top-level namespace for the Filevine v2 API client.
#
# The gem is designed for concurrent, multitenant use: construct one
# {UltimateFilevineClient::Client} per tenant with that tenant's own
# credentials. There is intentionally NO global/module-level configuration,
# so two tenants never share credential or token state.
#
#   client = UltimateFilevineClient::Client.new(config: tenant_config)
#   client.projects.list
module UltimateFilevineClient
  # Base class for every error raised by this gem. Rescue this to catch all
  # gem-originated failures. Subclasses are defined alongside the HTTP layer.
  class Error < StandardError; end
end
