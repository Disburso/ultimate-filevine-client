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

  it "keys the token cache by region + client_id (stable across org/user bootstrap)" do
    expect(config.token_key).to eq("filevine:token:us:cid")
    with_org = config.with(org_id: "org9", user_id: "u1")
    expect(with_org.token_key).to eq("filevine:token:us:cid")
  end

  it "#with returns a new frozen config with overrides, reusing the token store" do
    updated = config.with(org_id: "o", user_id: "u")
    expect(updated).to be_frozen
    expect([updated.org_id, updated.user_id]).to eq(%w[o u])
    expect(updated.token_store).to be(config.token_store)
    expect(updated.credentials.client_id).to eq("cid")
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
