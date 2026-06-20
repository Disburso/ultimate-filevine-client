# frozen_string_literal: true

# Covers the Documents-family extras beyond CRUD + the byte-transfer flow:
# filename search, recently-opened, the cursor-paged document series (+ its meta),
# and the bulk copy/move/remove-tag operations.
RSpec.describe "Documents extras" do # rubocop:disable RSpec/DescribeClass
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

  describe "#search" do
    it "GETs /DocumentSearch with required searchTerm + projectId and returns Documents" do
      stub_request(:get, "#{base}/fv-app/v2/DocumentSearch")
        .with(query: { "limit" => "50", "offset" => "0", "searchTerm" => "brief", "projectId" => "9" })
        .to_return(ok({ Items: [{ "DocumentId" => { "Native" => 3 }, "Filename" => "brief.pdf",
                                  "FolderName" => "Pleadings" }], HasMore: false }))
      doc = client.documents.search(search_term: "brief", project_id: 9).first
      expect([doc.id, doc.filename, doc.folder_name]).to eq([3, "brief.pdf", "Pleadings"])
    end
  end

  describe "#recent" do
    it "GETs /RecentlyOpenedDocuments, passing an optional projectId through" do
      stub_request(:get, "#{base}/fv-app/v2/RecentlyOpenedDocuments")
        .with(query: { "limit" => "50", "offset" => "0", "projectId" => "9" })
        .to_return(ok({ Items: [{ "DocumentId" => { "Native" => 7 }, "Filename" => "recent.pdf" }],
                        HasMore: false }))
      expect(client.documents.recent(projectId: 9).first.id).to eq(7)
    end
  end

  describe "#series" do
    it "cursor-pages /DocumentSeries by carrying LastID back as lastId" do
      stub_request(:get, "#{base}/fv-app/v2/DocumentSeries")
        .with(query: { "limit" => "50" })
        .to_return(ok({ Items: [{ "DocumentId" => { "Native" => 1 } }], LastID: 500, HasMore: true }))
      stub_request(:get, "#{base}/fv-app/v2/DocumentSeries")
        .with(query: { "limit" => "50", "lastId" => "500" })
        .to_return(ok({ Items: [{ "DocumentId" => { "Native" => 2 } }], LastID: 700, HasMore: false }))
      expect(client.documents.series.map(&:id)).to eq([1, 2])
    end
  end

  describe "#series_meta" do
    it "returns the raw DocSeriesMeta counts" do
      stub_request(:get, "#{base}/fv-app/v2/DocumentSeries/Meta")
        .with(query: { "projectId" => "9" })
        .to_return(ok({ "Count" => 12, "MinDocId" => 100, "MaxDocId" => 200 }))
      meta = client.documents.series_meta(projectId: 9)
      expect([meta["Count"], meta["MinDocId"], meta["MaxDocId"]]).to eq([12, 100, 200])
    end
  end

  describe "#copy / #move" do
    it "copies documents and returns the bulk-operation result (201)" do
      stub_request(:post, "#{base}/fv-app/v2/Documents/copy")
        .with(body: { "DestinationFolderId" => { "Native" => 5 }, "DocumentIds" => [{ "Native" => 3 }] })
        .to_return(status: 201, headers: { "Content-Type" => "application/json" },
                   body: { Message: "All operations successful",
                           Results: [{ Id: "3", Status: 201, NewId: "9" }] }.to_json)
      result = client.documents.copy(DestinationFolderId: { Native: 5 }, DocumentIds: [{ Native: 3 }])
      expect([result["Message"], result["Results"].first["NewId"]]).to eq(["All operations successful", "9"])
    end

    it "moves documents (200) and returns the result" do
      stub_request(:post, "#{base}/fv-app/v2/Documents/move")
        .with(body: { "DestinationFolderId" => { "Native" => 5 }, "DocumentIds" => [{ "Native" => 3 }] })
        .to_return(ok({ Message: "All operations successful", Results: [{ Id: "3", Status: 200 }] }))
      result = client.documents.move(DestinationFolderId: { Native: 5 }, DocumentIds: [{ Native: 3 }])
      expect(result["Results"].first["Status"]).to eq(200)
    end
  end

  describe "#remove_tag" do
    it "DELETEs /Documents/tags/{tag} with DocumentIds and returns nil on 204" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/Documents/tags/draft")
             .with(body: { "DocumentIds" => [{ "Native" => 3 }] })
             .to_return(status: 204, body: "")
      expect(client.documents.remove_tag("draft", document_ids: [{ Native: 3 }])).to be_nil
      expect(stub).to have_been_made.once
    end

    it "returns the multi-status body on a 207 partial failure" do
      stub_request(:delete, "#{base}/fv-app/v2/Documents/tags/draft")
        .to_return(status: 207, headers: { "Content-Type" => "application/json" },
                   body: { Message: "Partial success", Results: [{ Id: "3", Status: 404 }] }.to_json)
      result = client.documents.remove_tag("draft", document_ids: [{ Native: 3 }])
      expect(result["Message"]).to eq("Partial success")
    end
  end
end
