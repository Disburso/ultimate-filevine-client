# frozen_string_literal: true

# Helpers for the sandbox *recording pass* (see spec/recording/). Two modes:
#
#   * Replay (default): no live traffic. Committed cassettes are replayed under
#     deterministic dummy credentials, so CI verifies the client against real,
#     previously-recorded Filevine response shapes.
#   * Record (FILEVINE_RECORD set + real FILEVINE_* creds): performs the real
#     requests against a sandbox org and writes the cassettes. FILEVINE_RECORD=all
#     overwrites existing cassettes; any other truthy value records only what is
#     missing (VCR :once).
#
# Only ever point a recording pass at a sandbox org holding SYNTHETIC data: the
# response bodies are committed. Credentials, bearer tokens, and tenant ids are
# scrubbed (see spec/support/vcr.rb); arbitrary body PII is not.
module SandboxRecording
  CASSETTE_DIR = "spec/support/cassettes"
  CRED_ENV = %w[FILEVINE_CLIENT_ID FILEVINE_CLIENT_SECRET FILEVINE_PAT].freeze

  module_function

  # True when a recording pass was requested (FILEVINE_RECORD is set).
  def recording? = !ENV["FILEVINE_RECORD"].to_s.strip.empty?

  # VCR record mode for the default cassette options.
  def record_mode
    return :none unless recording?

    ENV["FILEVINE_RECORD"].strip.casecmp?("all") ? :all : :once
  end

  # True when real sandbox credentials are present (required to record).
  def credentials_present? = CRED_ENV.all? { |key| !ENV[key].to_s.strip.empty? }

  # True when the named cassette has already been recorded and committed.
  def cassette?(name) = File.exist?(File.join(CASSETTE_DIR, "#{name}.yml"))

  # A fresh client for one cassette. Real creds while recording; deterministic
  # dummies on replay (requests match on method+path+query, never on the scrubbed
  # auth/tenant values, so the dummies need not match what was recorded). Each
  # call gets its own token store, so every cassette records exactly one mint.
  def client(region: default_region)
    UltimateFilevineClient::Client.new(config: configuration(region))
  end

  # Resolve the tenant from a bootstrap payload and return a client that sends
  # x-fv-orgid / x-fv-userid. Reuses the source client's token store, so the
  # token minted for the bootstrap call is reused (one mint per cassette). An ENV
  # override wins while recording (e.g. to pin a specific sandbox org/user).
  def tenant_client(client, payload)
    org = env_or(payload&.dig("Orgs", 0, "OrgId"), "FILEVINE_ORG_ID")
    user = env_or(payload&.dig("User", "UserId"), "FILEVINE_USER_ID")
    UltimateFilevineClient::Client.new(config: client.config.with(org_id: org, user_id: user))
  end

  def configuration(region)
    creds = recording? ? live_credentials : dummy_credentials
    UltimateFilevineClient::Configuration.new(**creds, region: region, retry_interval: 0)
  end

  def live_credentials
    { client_id: ENV.fetch("FILEVINE_CLIENT_ID"),
      client_secret: ENV.fetch("FILEVINE_CLIENT_SECRET"),
      pat: ENV.fetch("FILEVINE_PAT") }
  end

  def dummy_credentials
    { client_id: "sandbox-client-id", client_secret: "sandbox-client-secret", pat: "sandbox-pat" }
  end

  def default_region = (ENV["FILEVINE_REGION"] || "us").to_sym

  def env_or(fallback, key)
    value = ENV[key].to_s.strip
    value.empty? ? fallback : value
  end
end
