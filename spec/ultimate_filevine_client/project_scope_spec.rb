# frozen_string_literal: true

# Covers the project-scoped sub-resources reached via client.project(id).
# Special attention is paid to the spec's case-sensitive, inconsistently-cased
# paths (e.g. capitalized /Projects on some ops, lowercase /projects on others).
RSpec.describe UltimateFilevineClient::ProjectScope do
  subject(:scope) { client.project(7) }

  let(:client) { UltimateFilevineClient::Client.new(config:) }
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

  def stub_list(path, items)
    stub_request(:get, "#{base}#{path}").with(query: { "limit" => "50", "offset" => "0" })
                                        .to_return(ok({ Items: items, HasMore: false }))
  end

  it "exposes the project id" do
    expect(scope.id).to eq(7)
  end

  describe "contacts" do
    it "lists ProjectContact entities (capitalized /Projects path)" do
      stub_list("/fv-app/v2/Projects/7/contacts",
                [{ "ProjectContactId" => { "Native" => 3 }, "Role" => "Plaintiff",
                   "OrgContact" => { "FullName" => "Jane Smith" } }])
      pc = scope.contacts.list.first
      expect(pc).to be_a(UltimateFilevineClient::Entities::ProjectContact)
      expect([pc.id, pc.role, pc.org_contact.full_name]).to eq([3, "Plaintiff", "Jane Smith"])
    end

    it "adds and removes a contact" do
      add = stub_request(:post, "#{base}/fv-app/v2/Projects/7/contacts")
            .to_return(ok({ "ProjectContactId" => { "Native" => 9 } }))
      del = stub_request(:delete, "#{base}/fv-app/v2/Projects/7/contacts/9").to_return(ok({}))
      expect(scope.contacts.add(OrgContactId: { Native: 5 }).id).to eq(9)
      expect(scope.contacts.remove(9)).to be(true)
      expect(add).to have_been_made.once
      expect(del).to have_been_made.once
    end
  end

  describe "deadlines" do
    it "runs full CRUD against the lowercase /projects path" do
      stub_list("/fv-app/v2/projects/7/deadlines",
                [{ "DeadlineId" => { "Native" => 1 }, "Name" => "Answer", "DoneDate" => nil }])
      deadline = scope.deadlines.list.first
      expect([deadline.id, deadline.name, deadline.completed?]).to eq([1, "Answer", false])

      stub_request(:get, "#{base}/fv-app/v2/projects/7/deadlines/1")
        .to_return(ok({ "DeadlineId" => { "Native" => 1 }, "DoneDate" => "2026-07-01T00:00:00Z" }))
      expect(scope.deadlines.get(1).completed?).to be(true)

      stub_request(:delete, "#{base}/fv-app/v2/projects/7/deadlines/1").to_return(ok({}))
      expect(scope.deadlines.delete(1)).to be(true)
    end
  end

  describe "deadline_chains (casing trap: capital create, lowercase others)" do
    it "creates on /Projects/.../DeadlineChains but lists on /projects/.../deadlinechains" do
      create = stub_request(:post, "#{base}/fv-app/v2/Projects/7/DeadlineChains")
               .to_return(ok({ "DeadlineChainId" => { "Native" => 2 }, "Name" => "Discovery" }))
      expect(scope.deadline_chains.create(Name: "Discovery").id).to eq(2)
      expect(create).to have_been_made.once

      stub_list("/fv-app/v2/projects/7/deadlinechains", [{ "DeadlineChainId" => { "Native" => 2 } }])
      expect(scope.deadline_chains.list.first.id).to eq(2)
    end

    it "updates a chain date and returns the parent chain" do
      stub_request(:patch, "#{base}/fv-app/v2/projects/7/chaindates/55/update")
        .to_return(ok({ "DeadlineChainId" => { "Native" => 2 }, "Name" => "Discovery" }))
      expect(scope.deadline_chains.update_chain_date(55, DoneDate: "2026-07-01T00:00:00Z").name).to eq("Discovery")
    end
  end

  describe "team" do
    it "lists TeamMember entities (Fullname field)" do
      stub_list("/fv-app/v2/projects/7/team",
                [{ "UserId" => { "Native" => 4 }, "Fullname" => "Ada Lovelace", "IsAdmin" => true }])
      member = scope.team.list.first
      expect([member.id, member.full_name, member.admin?]).to eq([4, "Ada Lovelace", true])
    end

    it "assigns roles via PUT and returns the member" do
      stub_request(:put, "#{base}/fv-app/v2/projects/7/team/users/4/roles")
        .to_return(ok({ "UserId" => { "Native" => 4 } }))
      expect(scope.team.assign_roles(4, Roles: [{ OrgRoleId: { Native: 1 }, MakeFirst: true }]).id).to eq(4)
    end

    it "returns the project teams as a bare array (not paginated)" do
      stub_request(:get, "#{base}/fv-app/v2/projects/7/teams")
        .to_return(ok([{ "Name" => "Litigation" }]))
      expect(scope.team.teams).to eq([{ "Name" => "Litigation" }])
    end
  end

  describe "appointments (casing trap: scoped list/create, flat get/delete)" do
    it "lists/creates under /Projects/.../Appointments" do
      stub_list("/fv-app/v2/Projects/7/Appointments", [{ "AppointmentId" => { "Native" => 8 }, "Title" => "Depo" }])
      expect(scope.appointments.list.first.title).to eq("Depo")

      stub_request(:post, "#{base}/fv-app/v2/Projects/7/Appointments")
        .to_return(ok({ "AppointmentId" => { "Native" => 8 } }))
      expect(scope.appointments.create(Title: "Depo").id).to eq(8)
    end

    it "addresses a single appointment on the flat /Appointments path" do
      get = stub_request(:get, "#{base}/fv-app/v2/Appointments/8")
            .to_return(ok({ "AppointmentId" => { "Native" => 8 }, "Title" => "Depo" }))
      del = stub_request(:delete, "#{base}/fv-app/v2/Appointments/8").to_return(ok({}))
      expect(scope.appointments.get(8).title).to eq("Depo")
      expect(scope.appointments.delete(8)).to be(true)
      expect(get).to have_been_made.once
      expect(del).to have_been_made.once
    end
  end

  describe "notes (casing trap: capital list, lowercase pin)" do
    it "lists on /Projects/.../Notes and pins on /projects/.../notes" do
      stub_list("/fv-app/v2/Projects/7/Notes", [{ "NoteId" => { "Native" => 1 }, "Subject" => "Call" }])
      expect(scope.notes.list.first.subject).to eq("Call")

      pin = stub_request(:post, "#{base}/fv-app/v2/projects/7/notes/1/pin")
            .to_return(ok({ "NoteId" => { "Native" => 1 }, "IsPinnedToProject" => true }))
      expect(scope.notes.pin(1).id).to eq(1)
      expect(pin).to have_been_made.once
    end
  end

  describe "tasks" do
    it "lists the project task feed and unpins a task" do
      stub_list("/fv-app/v2/projects/7/tasks", [{ "NoteId" => { "Native" => 5 }, "Subject" => "Do it" }])
      expect(scope.tasks.list.first.subject).to eq("Do it")

      stub_request(:post, "#{base}/fv-app/v2/projects/7/tasks/5/unpin")
        .to_return(ok({ "NoteId" => { "Native" => 5 } }))
      expect(scope.tasks.unpin(5).id).to eq(5)
    end
  end

  describe "documents" do
    it "adds an existing document into a folder via query param" do
      add = stub_request(:post, "#{base}/fv-app/v2/Projects/7/Documents/3")
            .with(query: { "folderId" => "9" })
            .to_return(ok({ "DocumentId" => { "Native" => 3 }, "Filename" => "complaint.pdf" }))
      expect(scope.documents.add(3, folder_id: 9).filename).to eq("complaint.pdf")
      expect(add).to have_been_made.once
    end
  end

  describe "emails" do
    it "lists Note-backed emails and posts a base64 message" do
      stub_list("/fv-app/v2/projects/7/emails", [{ "NoteId" => { "Native" => 1 }, "Subject" => "Re: settlement" }])
      expect(scope.emails.list.first.subject).to eq("Re: settlement")

      stub = stub_request(:post, "#{base}/fv-app/v2/projects/7/encodedEmails")
             .with(body: { "Base64Encoding" => "ABC123" })
             .to_return(ok({ "NoteId" => { "Native" => 2 } }))
      expect(scope.emails.add_encoded("ABC123").id).to eq(2)
      expect(stub).to have_been_made.once
    end
  end

  describe "collections (selector-based custom data)" do
    it "auto-pages CollectionItem entities and reads the freeform DataObject" do
      stub_request(:get, "#{base}/fv-app/v2/Projects/7/Collections/Damages")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [{ "ItemId" => { "Native" => 11 }, "DataObject" => { "Amount" => 5000 } }],
                        HasMore: false }))
      item = scope.collections("Damages").list.first
      expect([item.id, item.data]).to eq([11, { "Amount" => 5000 }])
    end

    it "updates a collection item by unique id" do
      stub_request(:patch, "#{base}/fv-app/v2/Projects/7/Collections/Damages/11")
        .to_return(ok({ "ItemId" => { "Native" => 11 } }))
      expect(scope.collections("Damages").update(11, DataObject: { Amount: 6000 }).id).to eq(11)
    end
  end

  describe "forms / vitals / core actions (raw payloads)" do
    it "reads a form section as a raw hash" do
      stub_request(:get, "#{base}/fv-app/v2/Projects/7/Forms/intake")
        .to_return(ok({ "OrgId" => 99, "Field" => "value" }))
      expect(scope.forms("intake").get).to eq({ "OrgId" => 99, "Field" => "value" })
    end

    it "reads project vitals as a raw array" do
      stub_request(:get, "#{base}/fv-app/v2/Projects/7/Vitals")
        .to_return(ok([{ "Name" => "Phase", "Value" => "Discovery" }]))
      expect(scope.vitals).to eq([{ "Name" => "Phase", "Value" => "Discovery" }])
    end

    it "toggles section visibility (lowercase /projects path) and returns true" do
      stub = stub_request(:post, "#{base}/fv-app/v2/projects/7/sectionvisibility")
             .with(body: { "SectionSelector" => "damages", "SectionVisibility" => "Hidden" })
             .to_return(ok({}))
      expect(scope.toggle_section_visibility(section_selector: "damages", section_visibility: "Hidden")).to be(true)
      expect(stub).to have_been_made.once
    end
  end
end
