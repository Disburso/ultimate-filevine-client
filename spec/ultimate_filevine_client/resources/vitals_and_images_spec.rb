# frozen_string_literal: true

# Covers the two standalone single-GET resources: the org-level Vitals endpoint
# (GET /fv-app/vitals — note: no /v2 segment, projectId is a query param) and
# Images (GET /fv-app/v2/images/{id}, JSON envelope by default or raw bytes).
RSpec.describe "Vitals and Images resources" do # rubocop:disable RSpec/DescribeClass
  subject(:client) { UltimateFilevineClient::Client.new(config:) }

  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:config) do
    UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "s", pat: "p", region: :us, token_store: store, retry_interval: 0
    )
  end
  let(:base) { "https://api.filevineapp.com" }

  before do
    store.write(config.token_key,
                UltimateFilevineClient::Auth::Token.new(value: "tok", expires_at: Time.now + 3600))
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "vitals" do
    it "fetches a project's vitals from the no-/v2 /fv-app/vitals path with projectId as a query param" do
      stub_request(:get, "#{base}/fv-app/vitals")
        .with(query: { "projectId" => "7" })
        .to_return(ok({ "ProjectId" => { "Native" => 7 }, "ProjectName" => "Smith v. Acme" }))
      expect(client.vitals.get(7)).to eq({ "ProjectId" => { "Native" => 7 }, "ProjectName" => "Smith v. Acme" })
    end

    it "forwards an optional requestedFields projection" do
      stub = stub_request(:get, "#{base}/fv-app/vitals")
             .with(query: { "projectId" => "7", "requestedFields" => "ProjectName" })
             .to_return(ok({ "ProjectName" => "Smith v. Acme" }))
      expect(client.vitals.get(7, requested_fields: "ProjectName")).to eq({ "ProjectName" => "Smith v. Acme" })
      expect(stub).to have_been_made.once
    end
  end

  describe "images" do
    it "returns the JSON envelope by default (no asJson query param sent)" do
      stub = stub_request(:get, "#{base}/fv-app/v2/images/55")
             .to_return(ok({ "ContentType" => "image/png", "Data" => "aGVsbG8=" }))
      expect(client.images.get(55)).to eq({ "ContentType" => "image/png", "Data" => "aGVsbG8=" })
      expect(stub).to have_been_made.once
    end

    it "returns raw bytes (undecoded) when as_json: false" do
      bytes = "\x89PNG\r\n\x1a\n".dup.force_encoding(Encoding::BINARY)
      stub_request(:get, "#{base}/fv-app/v2/images/55")
        .with(query: { "asJson" => "false" })
        .to_return(status: 200, headers: { "Content-Type" => "image/png" }, body: bytes)
      expect(client.images.get(55, as_json: false)).to eq(bytes)
    end
  end
end
