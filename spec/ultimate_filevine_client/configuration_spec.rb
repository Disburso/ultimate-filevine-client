# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Configuration do
  subject(:config) do
    described_class.new(client_id: "cid", client_secret: "sec", pat: "pat", region: :us)
  end

  it "resolves US base URLs" do
    expect(config.api_base_url).to eq("https://api.filevineapp.com")
    expect(config.identity_base_url).to eq("https://identity.filevine.com")
  end

  it "is frozen (immutable, lock-free to read across threads)" do
    expect(config).to be_frozen
  end

  it "defaults to a thread-safe in-memory token store" do
    expect(config.token_store).to be_a(UltimateFilevineClient::TokenStore::MemoryStore)
  end

  it "uses the documented default gateway scope" do
    expect(config.scope).to include("fv.api.gateway.access", "filevine.v2.api.*", "fv.auth.tenant.read")
  end

  it "keys the token cache per tenant, preferring org_id" do
    keyed = described_class.new(client_id: "cid", client_secret: "s", pat: "p", org_id: "org9", user_id: "u1")
    expect(keyed.token_key).to eq("filevine:token:us:org9")
  end

  it "falls back to client_id for the token key before bootstrap" do
    expect(config.token_key).to eq("filevine:token:us:cid")
  end

  it "raises ConfigurationError for an unknown region" do
    expect { described_class.new(client_id: "c", client_secret: "s", pat: "p", region: :mars) }
      .to raise_error(UltimateFilevineClient::ConfigurationError, /Unsupported region/)
  end

  it "raises ConfigurationError for missing credentials" do
    expect { described_class.new(client_id: "", client_secret: "s", pat: "p") }
      .to raise_error(UltimateFilevineClient::ConfigurationError, /client_id/)
  end
end
