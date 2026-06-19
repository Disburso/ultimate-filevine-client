# frozen_string_literal: true

module UltimateFilevineClient
  # The per-tenant entry point. Construct one Client per tenant from that
  # tenant's {Configuration}; nothing is shared between Client instances.
  #
  #   config = UltimateFilevineClient::Configuration.new(
  #     client_id: ..., client_secret: ..., pat: ..., region: :us
  #   )
  #   client = UltimateFilevineClient::Client.new(config: config)
  #   client.access_token
  #
  # Clients are safe to use concurrently across threads.
  class Client
    attr_reader :config, :authenticator

    def initialize(config:)
      @config = config
      @authenticator = Auth::Authenticator.new(config: config)
    end

    # A valid bearer token for this tenant, minted/refreshed as needed.
    # @return [String]
    def access_token
      @authenticator.access_token
    end
  end
end
