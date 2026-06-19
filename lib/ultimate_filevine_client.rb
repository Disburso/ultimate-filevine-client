# frozen_string_literal: true

require "faraday"

# Top-level namespace for the Filevine v2 API client.
#
# The gem is designed for concurrent, multitenant use: construct one
# {UltimateFilevineClient::Client} per tenant with that tenant's own
# credentials. There is intentionally NO global/module-level configuration,
# so two tenants never share credential or token state.
#
#   config = UltimateFilevineClient::Configuration.new(
#     client_id: ..., client_secret: ..., pat: ..., region: :us
#   )
#   client = UltimateFilevineClient::Client.new(config: config)
#   client.access_token
module UltimateFilevineClient
  # Base class for every error raised by this gem. Rescue this to catch all
  # gem-originated failures.
  class Error < StandardError; end
end

require_relative "ultimate_filevine_client/version"
require_relative "ultimate_filevine_client/errors"
require_relative "ultimate_filevine_client/region"
require_relative "ultimate_filevine_client/auth/credentials"
require_relative "ultimate_filevine_client/auth/token"
require_relative "ultimate_filevine_client/token_store/base"
require_relative "ultimate_filevine_client/token_store/memory_store"
require_relative "ultimate_filevine_client/configuration"
require_relative "ultimate_filevine_client/auth/authenticator"
require_relative "ultimate_filevine_client/client"
