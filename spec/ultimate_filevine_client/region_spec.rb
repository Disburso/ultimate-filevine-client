# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Region do
  it "resolves the US cell to gateway + identity hosts" do
    hosts = described_class.resolve(:us)
    expect(hosts.api).to eq("https://api.filevineapp.com")
    expect(hosts.identity).to eq("https://identity.filevine.com")
  end

  it "accepts a string region key" do
    expect(described_class.resolve("us").api).to eq("https://api.filevineapp.com")
  end

  it "raises ConfigurationError for unconfirmed regions (ca/cjis)" do
    expect { described_class.resolve(:ca) }
      .to raise_error(UltimateFilevineClient::ConfigurationError, /Unsupported region/)
  end
end
