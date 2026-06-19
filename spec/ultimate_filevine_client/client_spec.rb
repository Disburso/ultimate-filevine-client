# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Client do
  subject(:client) { described_class.new(config: config) }

  let(:config) do
    UltimateFilevineClient::Configuration.new(client_id: "c", client_secret: "s", pat: "p", region: :us)
  end

  it "exposes its configuration" do
    expect(client.config).to eq(config)
  end

  it "delegates #access_token to its authenticator" do
    stub_request(:post, "https://identity.filevine.com/connect/token")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { access_token: "tok", expires_in: 3600 }.to_json)
    expect(client.access_token).to eq("tok")
  end

  it "gives each tenant an isolated authenticator (no shared state)" do
    other = described_class.new(
      config: UltimateFilevineClient::Configuration.new(
        client_id: "c2", client_secret: "s", pat: "p", region: :us
      )
    )
    expect(client.authenticator).not_to be(other.authenticator)
  end

  it "exposes a per-tenant connection" do
    expect(client.connection).to be_a(UltimateFilevineClient::Connection)
  end

  it "#user_orgs POSTs GetUserOrgsWithToken and returns the parsed payload" do
    stub_request(:post, "https://identity.filevine.com/connect/token")
      .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                 body: { access_token: "tok", expires_in: 3600 }.to_json)
    stub = stub_request(:post, "https://api.filevineapp.com/fv-app/v2/utils/GetUserOrgsWithToken")
           .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                      body: { User: { UserId: 1 }, Orgs: [{ OrgId: 5 }] }.to_json)
    payload = client.user_orgs
    expect(payload["Orgs"].first["OrgId"]).to eq(5)
    expect(stub).to have_been_made.once
  end
end
