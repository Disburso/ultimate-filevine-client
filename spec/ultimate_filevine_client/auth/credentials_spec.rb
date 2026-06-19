# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Auth::Credentials do
  it "exposes its fields and is frozen/immutable" do
    creds = described_class.new(client_id: "c", client_secret: "s", pat: "p")
    expect([creds.client_id, creds.client_secret, creds.pat]).to eq(%w[c s p])
    expect(creds).to be_frozen
  end

  it "rejects blank values with a ConfigurationError naming the field" do
    expect { described_class.new(client_id: "c", client_secret: "  ", pat: "p") }
      .to raise_error(UltimateFilevineClient::ConfigurationError, /client_secret/)
  end

  it "redacts secrets from inspect" do
    creds = described_class.new(client_id: "c", client_secret: "topsecret", pat: "patvalue")
    expect(creds.inspect).to include("client_id=\"c\"", "[FILTERED]")
    expect(creds.inspect).not_to include("topsecret", "patvalue")
  end
end
