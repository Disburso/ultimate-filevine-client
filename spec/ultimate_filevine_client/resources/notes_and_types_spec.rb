# frozen_string_literal: true

# Covers the Notes extras (move, remove_tag) and the two reference-data type
# resources: Contact Types (bare-int id) and Deadline Chain Types (Identifier id,
# lowercase /chaintypes path).
RSpec.describe "Notes extras and type resources" do # rubocop:disable RSpec/DescribeClass
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

  def stub_list(path, items, query: {})
    stub_request(:get, "#{base}#{path}")
      .with(query: { "limit" => "50", "offset" => "0" }.merge(query))
      .to_return(ok({ Items: items, HasMore: false }))
  end

  describe "notes#move" do
    it "POSTs source/destination/NoteIds and returns nil on a 204" do
      stub = stub_request(:post, "#{base}/fv-app/v2/Notes/move")
             .with(body: { "SourceProjectId" => { "Native" => 1 }, "DestinationProjectId" => { "Native" => 2 },
                           "NoteIds" => [{ "Native" => 5 }] })
             .to_return(status: 204, body: "")
      result = client.notes.move(note_ids: [{ Native: 5 }],
                                 source_project_id: { Native: 1 }, destination_project_id: { Native: 2 })
      expect(result).to be_nil
      expect(stub).to have_been_made.once
    end

    it "returns the multi-status result hash on a 207" do
      stub_request(:post, "#{base}/fv-app/v2/Notes/move")
        .to_return(status: 207, headers: { "Content-Type" => "application/json" },
                   body: { Message: "Partial success", Results: [{ Id: "5", Status: 422 }] }.to_json)
      result = client.notes.move(note_ids: [{ Native: 5 }],
                                 source_project_id: { Native: 1 }, destination_project_id: { Native: 2 })
      expect(result["Results"].first["Status"]).to eq(422)
    end
  end

  describe "notes#remove_tag" do
    it "DELETEs /Notes/tags/{tag} with NoteIds and returns nil on a 204" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/Notes/tags/urgent")
             .with(body: { "NoteIds" => [{ "Native" => 5 }] })
             .to_return(status: 204, body: "")
      expect(client.notes.remove_tag("urgent", note_ids: [{ Native: 5 }])).to be_nil
      expect(stub).to have_been_made.once
    end
  end

  describe "contact_types" do
    it "lists ContactType entities (bare-int id)" do
      stub_list("/fv-app/v2/ContactTypes", [{ "ContactTypeId" => 4, "Name" => "Expert" }])
      ct = client.contact_types.list.first
      expect(ct).to be_a(UltimateFilevineClient::Entities::ContactType)
      expect([ct.id, ct.name]).to eq([4, "Expert"])
    end

    it "creates a contact type by name" do
      stub = stub_request(:post, "#{base}/fv-app/v2/ContactTypes").with(body: { "Name" => "Witness" })
                                                                  .to_return(ok({ "ContactTypeId" => 9,
                                                                                  "Name" => "Witness" }))
      ct = client.contact_types.create("Witness")
      expect([ct.id, ct.name]).to eq([9, "Witness"])
      expect(stub).to have_been_made.once
    end
  end

  describe "deadline_chain_types" do
    it "lists ChainType entities from the lowercase /chaintypes path (Identifier id), with a name filter" do
      stub_list("/fv-app/v2/chaintypes",
                [{ "ChainTypeId" => { "Native" => 88 }, "Name" => "Discovery", "IsActive" => true }],
                query: { "name" => "Disc" })
      ct = client.deadline_chain_types.list(name: "Disc").first
      expect(ct).to be_a(UltimateFilevineClient::Entities::ChainType)
      expect([ct.id, ct.name, ct.active?]).to eq([88, "Discovery", true])
    end
  end
end
