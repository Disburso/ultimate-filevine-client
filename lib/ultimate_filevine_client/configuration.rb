# frozen_string_literal: true

module UltimateFilevineClient
  # Immutable, per-tenant configuration for a {Client}.
  #
  # Built from one tenant's credentials and frozen, so it can be read by many
  # threads without locking. The only mutable collaborator is {#token_store},
  # which is itself thread-safe. There is intentionally no global configuration.
  class Configuration
    # Canonical scope string for the gateway PAT flow (US). Append
    # "filevine.v2.webhooks" when subscribing to webhooks.
    DEFAULT_SCOPE = "fv.api.gateway.access tenant filevine.v2.api.* openid email fv.auth.tenant.read"
    DEFAULT_OPEN_TIMEOUT = 10
    DEFAULT_TIMEOUT = 30
    DEFAULT_EXPIRY_SKEW = 60
    DEFAULT_MAX_RETRIES = 2
    DEFAULT_RETRY_INTERVAL = 0.5

    attr_reader :credentials, :region, :api_base_url, :identity_base_url,
                :org_id, :user_id, :scope, :token_store, :adapter,
                :open_timeout, :timeout, :token_expiry_skew, :max_retries, :retry_interval

    def initialize(client_id:, client_secret:, pat:,
                   region: :us, org_id: nil, user_id: nil,
                   scope: DEFAULT_SCOPE, token_store: nil, adapter: nil,
                   open_timeout: DEFAULT_OPEN_TIMEOUT, timeout: DEFAULT_TIMEOUT,
                   token_expiry_skew: DEFAULT_EXPIRY_SKEW,
                   max_retries: DEFAULT_MAX_RETRIES, retry_interval: DEFAULT_RETRY_INTERVAL)
      @credentials = Auth::Credentials.new(client_id:, client_secret:, pat:)
      @region = region.to_sym
      hosts = Region.resolve(@region)
      @api_base_url = hosts.api
      @identity_base_url = hosts.identity
      @org_id = org_id
      @user_id = user_id
      @scope = scope
      @token_store = token_store || TokenStore::MemoryStore.new
      @adapter = adapter || Faraday.default_adapter
      @open_timeout = open_timeout
      @timeout = timeout
      @token_expiry_skew = token_expiry_skew
      @max_retries = max_retries
      @retry_interval = retry_interval
      freeze
    end

    # Per-tenant token cache key. The minted token depends only on the
    # credentials (org/user are per-request headers, not part of minting), so the
    # key is stable across org/user bootstrap.
    def token_key
      "filevine:token:#{region}:#{credentials.client_id}"
    end

    # Return a new frozen Configuration with the given overrides, reusing the
    # same token store. Used to populate org_id/user_id after bootstrap without
    # mutating this (frozen) instance.
    def with(org_id: @org_id, user_id: @user_id, scope: @scope, token_store: @token_store,
             adapter: @adapter, open_timeout: @open_timeout, timeout: @timeout,
             token_expiry_skew: @token_expiry_skew, max_retries: @max_retries,
             retry_interval: @retry_interval)
      self.class.new(
        client_id: credentials.client_id, client_secret: credentials.client_secret,
        pat: credentials.pat, region:, org_id:, user_id:, scope:, token_store:,
        adapter:, open_timeout:, timeout:, token_expiry_skew:, max_retries:, retry_interval:
      )
    end
  end
end
