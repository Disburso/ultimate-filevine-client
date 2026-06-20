# frozen_string_literal: true

# Covers the Custom Contacts resource (delta-style writes + freeform reads) and
# the org-level Teams resource (bare-array list, 204 action writes, project
# assignment).
RSpec.describe "Custom Contacts and Org Teams" do # rubocop:disable RSpec/DescribeClass
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

  describe "custom_contacts" do
    it "returns contact field metadata as a bare array" do
      stub_request(:get, "#{base}/fv-app/v2/Custom-Contacts-Meta")
        .to_return(ok([{ "FieldName" => "Nickname", "Selector" => "nickname" }]))
      expect(client.custom_contacts.meta.first["FieldName"]).to eq("Nickname")
    end

    it "creates a custom contact from a bare array of update directives" do
      requests = [{ Action: "Add", Selector: "nickname", Value: "JJ" }]
      stub = stub_request(:post, "#{base}/fv-app/v2/Custom-Contacts/7")
             .with(body: [{ "Action" => "Add", "Selector" => "nickname", "Value" => "JJ" }])
             .to_return(ok({ "PersonId" => { "Native" => 7 }, "FullName" => "Jane Jones" }))
      contact = client.custom_contacts.create(7, requests)
      expect(contact).to be_a(UltimateFilevineClient::Entities::Contact)
      expect([contact.id, contact.full_name]).to eq([7, "Jane Jones"])
      expect(stub).to have_been_made.once
    end

    it "reads a custom-data tab as a raw hash" do
      stub_request(:get, "#{base}/fv-app/v2/Custom-Contacts/7/Custom-Data/3")
        .to_return(ok({ "TabId" => 3, "CustomData" => { "Foo" => "bar" } }))
      expect(client.custom_contacts.tab(7, 3)["CustomData"]).to eq({ "Foo" => "bar" })
    end
  end

  describe "teams" do
    it "lists teams from a bare array" do
      stub_request(:get, "#{base}/fv-app/v2/teams")
        .to_return(ok([{ "ID" => { "Native" => 2 }, "Name" => "Litigation", "OrgID" => 99 }]))
      team = client.teams.list.first
      expect(team).to be_a(UltimateFilevineClient::Entities::Team)
      expect([team.id, team.name, team.org_id]).to eq([2, "Litigation", 99])
    end

    it "gets a single team" do
      stub_request(:get, "#{base}/fv-app/v2/teams/2")
        .to_return(ok({ "ID" => { "Native" => 2 }, "MemberCount" => 4 }))
      expect(client.teams.get(2).member_count).to eq(4)
    end

    it "adds and removes members (204 actions)" do
      add = stub_request(:put, "#{base}/fv-app/v2/teams/2/members")
            .with(body: { "UserIDs" => [5], "AccessLevel" => 1 }).to_return(status: 204, body: "")
      rem = stub_request(:post, "#{base}/fv-app/v2/teams/2/members/remove")
            .with(body: { "UserIds" => [5] }).to_return(status: 204, body: "")
      expect(client.teams.add_members(2, UserIDs: [5], AccessLevel: 1)).to be(true)
      expect(client.teams.remove_members(2, UserIds: [5])).to be(true)
      expect(add).to have_been_made.once
      expect(rem).to have_been_made.once
    end

    it "pages a team's project access (raw hashes)" do
      stub_request(:get, "#{base}/fv-app/v2/teams/2/projects/access")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [{ "ProjectName" => "Smith v. Acme" }], HasMore: false }))
      expect(client.teams.projects_access(2).first).to eq({ "ProjectName" => "Smith v. Acme" })
    end

    it "adds a team to a project with applySubscriptions and removes it" do
      add = stub_request(:put, "#{base}/fv-app/v2/teams/2/projects/9")
            .with(query: { "applySubscriptions" => "true" }).to_return(status: 204, body: "")
      del = stub_request(:delete, "#{base}/fv-app/v2/teams/2/projects/9").to_return(status: 204, body: "")
      expect(client.teams.add_project(2, 9, apply_subscriptions: true)).to be(true)
      expect(client.teams.remove_project(2, 9)).to be(true)
      expect(add).to have_been_made.once
      expect(del).to have_been_made.once
    end

    it "bulk-assigns teams to projects via /teamprojects" do
      stub = stub_request(:put, "#{base}/fv-app/v2/teamprojects")
             .with(body: { "TeamIds" => [{ "Native" => 2 }], "ApplySubscriptions" => true })
             .to_return(status: 204, body: "")
      expect(client.teams.assign_to_projects(TeamIds: [{ Native: 2 }], ApplySubscriptions: true)).to be(true)
      expect(stub).to have_been_made.once
    end
  end
end
