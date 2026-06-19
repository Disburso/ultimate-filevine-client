# frozen_string_literal: true

# Covers the resources beyond Projects: Contacts, Documents, Notes, Tasks,
# Project Types. Projects has its own (more detailed) spec.
RSpec.describe "Additional resources" do # rubocop:disable RSpec/DescribeClass
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

  def stub_list(path, items)
    stub_request(:get, "#{base}#{path}").with(query: { "limit" => "50", "offset" => "0" })
                                        .to_return(ok({ Items: items, HasMore: false }))
  end

  describe "contacts" do
    it "lists Contact entities" do
      stub_list("/fv-app/v2/Contacts",
                [{ "PersonId" => { "Native" => 7 }, "FullName" => "Jane Smith", "PrimaryEmail" => "j@x.com" }])
      contact = client.contacts.list.first
      expect(contact).to be_a(UltimateFilevineClient::Entities::Contact)
      expect([contact.id, contact.full_name, contact.primary_email]).to eq([7, "Jane Smith", "j@x.com"])
    end

    it "gets a single contact" do
      stub_request(:get, "#{base}/fv-app/v2/Contacts/7")
        .to_return(ok({ "PersonId" => { "Native" => 7 }, "FullName" => "Jane Smith" }))
      expect(client.contacts.get(7).full_name).to eq("Jane Smith")
    end

    it "creates a contact" do
      stub = stub_request(:post, "#{base}/fv-app/v2/Contacts").with(body: { "FirstName" => "Jane" })
                                                              .to_return(ok({ "PersonId" => { "Native" => 9 } }))
      expect(client.contacts.create(FirstName: "Jane").id).to eq(9)
      expect(stub).to have_been_made.once
    end
  end

  describe "documents" do
    it "lists Document entities" do
      stub_list("/fv-app/v2/Documents",
                [{ "DocumentId" => { "Native" => 3 }, "Filename" => "complaint.pdf", "Size" => 1024 }])
      doc = client.documents.list.first
      expect([doc.id, doc.filename, doc.size]).to eq([3, "complaint.pdf", 1024])
    end

    it "deletes a document and returns true" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/Documents/3").to_return(ok({}))
      expect(client.documents.delete(3)).to be(true)
      expect(stub).to have_been_made.once
    end
  end

  describe "notes" do
    it "lists Note entities" do
      stub_list("/fv-app/v2/Notes", [{ "NoteId" => { "Native" => 1 }, "Subject" => "Call", "IsCompleted" => true }])
      note = client.notes.list.first
      expect([note.id, note.subject, note.completed?]).to eq([1, "Call", true])
    end

    it "creates a note" do
      stub_request(:post, "#{base}/fv-app/v2/Notes").to_return(ok({ "NoteId" => { "Native" => 2 }, "Body" => "hi" }))
      expect(client.notes.create(Body: "hi").body).to eq("hi")
    end
  end

  describe "tasks (lowercase path)" do
    it "lists Task entities from /fv-app/v2/tasks" do
      stub_list("/fv-app/v2/tasks", [{ "NoteId" => { "Native" => 5 }, "Subject" => "Do it" }])
      expect(client.tasks.list.first.subject).to eq("Do it")
    end

    it "gets a single task" do
      stub_request(:get, "#{base}/fv-app/v2/tasks/5").to_return(ok({ "TaskId" => { "Native" => 5 } }))
      expect(client.tasks.get(5).id).to eq(5)
    end
  end

  describe "project_types" do
    it "lists ProjectType entities" do
      stub_list("/fv-app/v2/ProjectTypes", [{ "ProjectTypeId" => { "Native" => 4 }, "Name" => "Personal Injury" }])
      pt = client.project_types.list.first
      expect([pt.id, pt.name]).to eq([4, "Personal Injury"])
    end

    it "auto-pages a project type's sections (raw hashes)" do
      stub_request(:get, "#{base}/fv-app/v2/ProjectTypes/4/sections")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [{ "Name" => "Intake" }], HasMore: false }))
      expect(client.project_types.sections(4).to_a).to eq([{ "Name" => "Intake" }])
    end
  end
end
