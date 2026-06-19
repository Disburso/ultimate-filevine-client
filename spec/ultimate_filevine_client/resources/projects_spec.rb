# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Resources::Projects do
  subject(:client) { UltimateFilevineClient::Client.new(config:) }

  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:config) do
    UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "s", pat: "p", region: :us,
      org_id: "org-7", user_id: "user-9", token_store: store, retry_interval: 0
    )
  end
  let(:base) { "https://api.filevineapp.com" }

  before do
    store.write(config.token_key,
                UltimateFilevineClient::Auth::Token.new(value: "tok", expires_at: Time.now + 3600))
  end

  def project(native, name)
    { "ProjectId" => { "Native" => native }, "ProjectName" => name }
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "#list" do
    it "returns an auto-paging collection of Project entities" do
      stub_request(:get, "#{base}/fv-app/v2/Projects")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [project(1, "A"), project(2, "B")], HasMore: true }))
      stub_request(:get, "#{base}/fv-app/v2/Projects")
        .with(query: { "limit" => "50", "offset" => "2" })
        .to_return(ok({ Items: [project(3, "C")], HasMore: false }))

      projects = client.projects.list.to_a
      expect(projects).to all(be_a(UltimateFilevineClient::Entities::Project))
      expect(projects.map(&:id)).to eq([1, 2, 3])
      expect(projects.map(&:name)).to eq(%w[A B C])
    end

    it "forwards limit and filter params" do
      stub = stub_request(:get, "#{base}/fv-app/v2/Projects")
             .with(query: { "limit" => "10", "offset" => "0", "requestedFields" => "ProjectName" })
             .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                        body: { Items: [], HasMore: false }.to_json)
      client.projects.list(limit: 10, requestedFields: "ProjectName").to_a
      expect(stub).to have_been_made.once
    end
  end

  describe "#get" do
    it "fetches a single Project" do
      stub_request(:get, "#{base}/fv-app/v2/Projects/88")
        .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                   body: project(88, "Smith v. Acme").to_json)
      result = client.projects.get(88)
      expect(result.id).to eq(88)
      expect(result.name).to eq("Smith v. Acme")
    end
  end

  describe "#create" do
    it "POSTs attributes and returns the created Project" do
      stub = stub_request(:post, "#{base}/fv-app/v2/Projects")
             .with(body: { "ProjectName" => "New Matter" })
             .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                        body: project(5, "New Matter").to_json)
      result = client.projects.create(ProjectName: "New Matter")
      expect(result.id).to eq(5)
      expect(stub).to have_been_made.once
    end
  end

  describe "#update" do
    it "PATCHes attributes and returns the updated Project" do
      stub = stub_request(:patch, "#{base}/fv-app/v2/Projects/5")
             .with(body: { "ProjectName" => "Renamed" })
             .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                        body: project(5, "Renamed").to_json)
      result = client.projects.update(5, ProjectName: "Renamed")
      expect(result.name).to eq("Renamed")
      expect(stub).to have_been_made.once
    end
  end

  describe "end-to-end via a recorded cassette (VCR)" do
    it "mints a token then auto-pages projects from the cassette" do
      # No seeded token: the cassette serves the /connect/token mint too.
      fresh = UltimateFilevineClient::Client.new(
        config: UltimateFilevineClient::Configuration.new(
          client_id: "cid", client_secret: "s", pat: "p", region: :us, retry_interval: 0
        )
      )
      VCR.use_cassette("projects_list", match_requests_on: %i[method path query]) do
        names = fresh.projects.list(limit: 2).map(&:name)
        expect(names).to eq(["Smith v. Acme", "Doe v. Roe", "Roe v. City"])
      end
    end
  end
end
