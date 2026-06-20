# frozen_string_literal: true

# Covers the document presigned-URL byte-transfer flow: the high-level
# upload/download helpers (which cross out to S3 over a separate connection) plus
# the low-level batch + revision/lock steps.
RSpec.describe "Document transfer" do # rubocop:disable RSpec/DescribeClass
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

  def json(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "#upload" do
    it "requests a URL, PUTs the bytes to S3, then commits to the project" do
      create = stub_request(:post, "#{base}/fv-app/v2/Documents")
               .with(body: { "Filename" => "complaint.pdf", "Size" => 7, "ProjectId" => { "Native" => 9 } })
               .to_return(json(Url: "https://s3.example/up?sig=abc", DocumentId: { Native: 5 },
                               ContentType: "application/pdf"))
      put = stub_request(:put, "https://s3.example/up?sig=abc")
            .with(body: "PDFDATA", headers: { "Content-Type" => "application/pdf" })
            .to_return(status: 200, body: "")
      commit = stub_request(:post, "#{base}/fv-app/v2/Projects/9/Documents/5")
               .to_return(json(DocumentId: { Native: 5 }))

      locator = client.documents.upload("PDFDATA", filename: "complaint.pdf", project_id: 9)

      expect(locator["DocumentId"]["Native"]).to eq(5)
      expect(create).to have_been_made.once
      expect(put).to have_been_made.once
      expect(commit).to have_been_made.once
    end

    it "skips the commit when no project is given" do
      stub_request(:post, "#{base}/fv-app/v2/Documents")
        .to_return(json(Url: "https://s3.example/up?sig=abc", DocumentId: { Native: 5 }, ContentType: "text/plain"))
      put = stub_request(:put, "https://s3.example/up?sig=abc").to_return(status: 200, body: "")
      client.documents.upload("hello", filename: "note.txt")
      expect(put).to have_been_made.once
      expect(a_request(:post, %r{/Projects/})).not_to have_been_made
    end
  end

  describe "#download" do
    it "resolves the locator then GETs the raw bytes from S3" do
      stub_request(:get, "#{base}/fv-app/v2/Documents/5/locator")
        .to_return(json(Url: "https://s3.example/dl?sig=xyz", ContentType: "application/pdf"))
      s3 = stub_request(:get, "https://s3.example/dl?sig=xyz").to_return(status: 200, body: "RAWBYTES")
      expect(client.documents.download(5)).to eq("RAWBYTES")
      expect(s3).to have_been_made.once
    end

    it "raises a TransferError without leaking the presigned signature" do
      stub_request(:get, "#{base}/fv-app/v2/Documents/6/locator")
        .to_return(json(Url: "https://s3.example/dl?sig=secret"))
      stub_request(:get, "https://s3.example/dl?sig=secret").to_return(status: 403, body: "AccessDenied")
      expect { client.documents.download(6) }.to raise_error(UltimateFilevineClient::TransferError) do |e|
        expect(e.status).to eq(403)
        expect(e.message).not_to include("secret")
        expect(e.url).to eq("https://s3.example/dl")
      end
    end
  end

  describe "low-level steps" do
    it "runs the batch upload + confirm flow" do
      stub_request(:post, "#{base}/fv-app/v2/Documents/batch/upload")
        .to_return(json([{ DocumentId: 5, UploadUrl: "https://s3.example/u1", IsMultipartUpload: false }]))
      responses = client.documents.batch_upload(Files: [{ ProjectId: 9, SizeInBytes: 10, SizeInBits: 80 }])
      expect(responses.first["UploadUrl"]).to eq("https://s3.example/u1")

      confirm = stub_request(:post, "#{base}/fv-app/v2/Documents/batch/upload/confirm")
                .with(body: { "DocumentIds" => [5] }).to_return(json(true))
      expect(client.documents.confirm_upload([5])).to be(true)
      expect(confirm).to have_been_made.once
    end

    it "batch-downloads presigned links" do
      stub_request(:post, "#{base}/fv-app/v2/Documents/batch/download")
        .with(body: { "DocumentIds" => [5, 6], "DownloadUrlTimeToLive" => 600 })
        .to_return(json([{ DocumentId: 5, DownloadLink: "https://s3.example/d5" }]))
      result = client.documents.batch_download([5, 6], time_to_live: 600)
      expect(result.first["DownloadLink"]).to eq("https://s3.example/d5")
    end

    it "adds a revision and locks a document (returns Document entities)" do
      stub_request(:post, "#{base}/fv-app/v2/Documents/5/Revisions")
        .with(body: { "Native" => 8 })
        .to_return(json("DocumentId" => { "Native" => 5 }, "Filename" => "v2.pdf"))
      expect(client.documents.add_revision(5, 8).filename).to eq("v2.pdf")

      stub_request(:post, "#{base}/fv-app/v2/Documents/5/lock").to_return(json("DocumentId" => { "Native" => 5 }))
      expect(client.documents.lock(5).id).to eq(5)
    end
  end
end
