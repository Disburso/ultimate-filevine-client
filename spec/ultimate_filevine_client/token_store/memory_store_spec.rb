# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::TokenStore::MemoryStore do
  subject(:store) { described_class.new }

  let(:token) { UltimateFilevineClient::Auth::Token.new(value: "t", expires_at: Time.now + 3600) }

  it "writes and reads a token per key" do
    store.write("k", token)
    expect(store.read("k")).to eq(token)
  end

  it "returns nil for missing keys" do
    expect(store.read("missing")).to be_nil
  end

  it "deletes a key" do
    store.write("k", token)
    store.delete("k")
    expect(store.read("k")).to be_nil
  end

  it "isolates keys (per-tenant separation)" do
    other = UltimateFilevineClient::Auth::Token.new(value: "u", expires_at: Time.now + 3600)
    store.write("tenant-a", token)
    store.write("tenant-b", other)
    expect([store.read("tenant-a").value, store.read("tenant-b").value]).to eq(%w[t u])
  end
end
