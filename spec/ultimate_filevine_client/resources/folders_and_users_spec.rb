# frozen_string_literal: true

# Covers the org-level Folders and Users resources. Both have case-sensitive
# path quirks: Folders is capitalized with a lowercase /Folders/list endpoint;
# Users uses /Users (and /Users/Me) for the org list but lowercase /users/{id}
# for per-user reads.
RSpec.describe "Folders and Users resources" do # rubocop:disable RSpec/DescribeClass
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

  def stub_list(path, items, query: { "limit" => "50", "offset" => "0" })
    stub_request(:get, "#{base}#{path}").with(query: query)
                                        .to_return(ok({ Items: items, HasMore: false }))
  end

  describe "folders" do
    it "lists Folder entities under the capitalized /Folders path" do
      stub_list("/fv-app/v2/Folders",
                [{ "FolderId" => { "Native" => 1 }, "Name" => "Pleadings", "IsArchived" => false }])
      folder = client.folders.list.first
      expect(folder).to be_a(UltimateFilevineClient::Entities::Folder)
      expect([folder.id, folder.name, folder.archived?]).to eq([1, "Pleadings", false])
    end

    it "creates, updates and deletes a folder" do
      create = stub_request(:post, "#{base}/fv-app/v2/Folders")
               .to_return(ok({ "FolderId" => { "Native" => 5 }, "Name" => "New" }))
      del = stub_request(:delete, "#{base}/fv-app/v2/Folders/5").to_return(ok({}))
      expect(client.folders.create(Name: "New", ParentId: { Native: 0 }, IsArchived: false).id).to eq(5)
      expect(client.folders.delete(5)).to be(true)
      expect(create).to have_been_made.once
      expect(del).to have_been_made.once
    end

    it "pages a folder's children" do
      stub_list("/fv-app/v2/Folders/2/children", [{ "FolderId" => { "Native" => 3 } }])
      expect(client.folders.children(2).first.id).to eq(3)
    end

    it "walks the project structure with a required projectId" do
      stub_list("/fv-app/v2/Folders/list",
                [{ "FolderId" => { "Native" => 9 } }],
                query: { "limit" => "50", "offset" => "0", "projectId" => "7" })
      expect(client.folders.structure(7).first.id).to eq(9)
    end
  end

  describe "users" do
    it "lists User entities under the capitalized /Users path" do
      stub_list("/fv-app/v2/Users",
                [{ "OrgUserId" => { "Native" => 1 }, "Email" => "a@x.com",
                   "User" => { "FirstName" => "Ada", "LastName" => "Lovelace" } }])
      user = client.users.list.first
      expect(user).to be_a(UltimateFilevineClient::Entities::User)
      expect([user.id, user.email, user.first_name, user.last_name]).to eq([1, "a@x.com", "Ada", "Lovelace"])
    end

    it "fetches the current user from /Users/Me (capital U)" do
      stub_request(:get, "#{base}/fv-app/v2/Users/Me")
        .to_return(ok({ "OrgUserId" => { "Native" => 42 }, "UserName" => "api-svc" }))
      expect([client.users.me.id, client.users.me.username]).to eq([42, "api-svc"])
    end

    it "fetches a single user from the lowercase /users/{id} path" do
      stub_request(:get, "#{base}/fv-app/v2/users/4")
        .to_return(ok({ "OrgUserId" => { "Native" => 4 }, "IsActive" => true }))
      expect(client.users.get(4).active?).to be(true)
    end

    it "pages a user's tasks (Note-backed) and appointments" do
      stub_list("/fv-app/v2/users/4/tasks", [{ "NoteId" => { "Native" => 8 }, "Subject" => "Review" }])
      expect(client.users.tasks(4).first.subject).to eq("Review")

      stub_list("/fv-app/v2/users/4/appointments", [{ "AppointmentId" => { "Native" => 2 }, "Title" => "Call" }])
      expect(client.users.appointments(4).first.title).to eq("Call")
    end

    it "pages projects access as raw hashes" do
      stub_list("/fv-app/v2/users/4/projects/access", [{ "ProjectId" => { "Native" => 7 }, "AccessLevel" => "Full" }])
      expect(client.users.projects_access(4).first).to eq({ "ProjectId" => { "Native" => 7 },
                                                            "AccessLevel" => "Full" })
    end

    it "returns recent projects from a bare array (not paginated)" do
      stub_request(:get, "#{base}/fv-app/v2/users/4/recentprojects")
        .to_return(ok([{ "ProjectId" => { "Native" => 1 }, "ProjectName" => "Smith v. Acme" }]))
      projects = client.users.recent_projects(4)
      expect(projects.first).to be_a(UltimateFilevineClient::Entities::Project)
      expect(projects.first.name).to eq("Smith v. Acme")
    end
  end
end
