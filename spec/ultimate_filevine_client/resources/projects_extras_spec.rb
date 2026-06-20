# frozen_string_literal: true

# Covers the Projects-family extras beyond core CRUD: archive, bulk tag removal,
# applying a hashtag, bulk client updates, and conflict check — plus the
# ProjectScope delegators. These exercise the family's inconsistent path casing
# (lowercase /projects vs capital /Projects vs capital /Utils).
RSpec.describe "Projects extras" do # rubocop:disable RSpec/DescribeClass
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

  describe "#archive" do
    it "DELETEs the LOWERCASE /projects/{id} path and returns true" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/projects/5").to_return(status: 200, body: "")
      expect(client.projects.archive(5)).to be(true)
      expect(stub).to have_been_made.once
    end
  end

  describe "#remove_tag" do
    it "DELETEs capital /Projects/tags/{tag} with ProjectIds and returns nil on 204" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/Projects/tags/urgent")
             .with(body: { "ProjectIds" => [{ "Native" => 5 }, { "Native" => 6 }] })
             .to_return(status: 204, body: "")
      result = client.projects.remove_tag("urgent", project_ids: [{ Native: 5 }, { Native: 6 }])
      expect(result).to be_nil
      expect(stub).to have_been_made.once
    end

    it "returns the multi-status result body on a 207 partial failure" do
      stub_request(:delete, "#{base}/fv-app/v2/Projects/tags/urgent")
        .to_return(status: 207, headers: { "Content-Type" => "application/json" },
                   body: { Message: "Partial success", Results: [{ Id: "6", Status: 404 }] }.to_json)
      result = client.projects.remove_tag("urgent", project_ids: [{ Native: 5 }])
      expect(result["Message"]).to eq("Partial success")
      expect(result["Results"].first["Status"]).to eq(404)
    end
  end

  describe "#add_hashtag" do
    it "POSTs to lowercase /hashtags/{tag} and returns a Hashtag with counts" do
      stub = stub_request(:post, "#{base}/fv-app/v2/hashtags/big-case")
             .with(body: { "Projects" => [{ "Native" => 5 }] })
             .to_return(ok({ "Name" => "big-case", "ProjectCount" => 1, "DocCount" => 0,
                             "NoteCount" => 0, "CommentCount" => 0 }))
      tag = client.projects.add_hashtag("big-case", projects: [{ Native: 5 }])
      expect(tag).to be_a(UltimateFilevineClient::Entities::Hashtag)
      expect([tag.name, tag.project_count]).to eq(["big-case", 1])
      expect(stub).to have_been_made.once
    end
  end

  describe "#bulk_update_clients" do
    it "PUTs ProjectPersonPairs to /projects/bulk and returns true" do
      stub = stub_request(:put, "#{base}/fv-app/v2/projects/bulk")
             .with(body: { "ProjectPersonPairs" => [{ "ProjectId" => { "Native" => 5 },
                                                      "PersonId" => { "Native" => 9 } }] })
             .to_return(status: 200, body: "")
      result = client.projects.bulk_update_clients([{ ProjectId: { Native: 5 }, PersonId: { Native: 9 } }])
      expect(result).to be(true)
      expect(stub).to have_been_made.once
    end
  end

  describe "#conflict_check" do
    it "POSTs (no body) to capital /Utils/conflictcheck with a searchTerm query and returns raw results" do
      stub = stub_request(:post, "#{base}/fv-app/v2/Utils/conflictcheck/projects/5")
             .with(query: { "searchTerm" => "Smith" })
             .to_return(ok({ "Total" => 1, "Count" => 1,
                             "Results" => [{ "PersonID" => 7, "FullName" => "Jane Smith" }] }))
      result = client.projects.conflict_check(5, "Smith")
      expect(result["Total"]).to eq(1)
      expect(result["Results"].first["FullName"]).to eq("Jane Smith")
      expect(stub).to have_been_made.once
    end
  end

  describe "ProjectScope delegators" do
    it "archives and conflict-checks the scoped project" do
      archive = stub_request(:delete, "#{base}/fv-app/v2/projects/8").to_return(status: 200, body: "")
      check = stub_request(:post, "#{base}/fv-app/v2/Utils/conflictcheck/projects/8")
              .with(query: { "searchTerm" => "Acme" }).to_return(ok({ "Total" => 0, "Count" => 0 }))

      scope = client.project(8)
      expect(scope.archive).to be(true)
      expect(scope.conflict_check("Acme")["Total"]).to eq(0)
      expect(archive).to have_been_made.once
      expect(check).to have_been_made.once
    end
  end
end
