# frozen_string_literal: true

# Covers the standalone org-level resources: Appointments (by id), Comments
# (note-scoped), Share Links (cursor-paginated), and Reports.
RSpec.describe "Standalone org resources" do # rubocop:disable RSpec/DescribeClass
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

  describe "appointments" do
    it "gets, updates and deletes by appointment id (flat path)" do
      stub_request(:get, "#{base}/fv-app/v2/Appointments/8")
        .to_return(ok({ "AppointmentId" => { "Native" => 8 }, "Title" => "Depo" }))
      appt = client.appointments.get(8)
      expect(appt).to be_a(UltimateFilevineClient::Entities::Appointment)
      expect([appt.id, appt.title]).to eq([8, "Depo"])

      stub_request(:patch, "#{base}/fv-app/v2/Appointments/8")
        .to_return(ok({ "AppointmentId" => { "Native" => 8 }, "Location" => "Room 2" }))
      expect(client.appointments.update(8, Location: "Room 2").location).to eq("Room 2")

      del = stub_request(:delete, "#{base}/fv-app/v2/Appointments/8").to_return(status: 204, body: "")
      expect(client.appointments.delete(8)).to be(true)
      expect(del).to have_been_made.once
    end
  end

  describe "comments (note-scoped)" do
    it "lists comments under a note" do
      stub_request(:get, "#{base}/fv-app/v2/Notes/5/Comments")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [{ "CommentId" => { "Native" => 1 }, "Body" => "Looks good",
                                  "AuthorName" => "Ada" }], HasMore: false }))
      comment = client.comments.list(5).first
      expect(comment).to be_a(UltimateFilevineClient::Entities::Comment)
      expect([comment.id, comment.body, comment.author_name]).to eq([1, "Looks good", "Ada"])
    end

    it "creates and updates a comment" do
      stub_request(:post, "#{base}/fv-app/v2/Notes/5/Comments")
        .with(body: { "Body" => "Nice" })
        .to_return(ok({ "CommentId" => { "Native" => 2 }, "Body" => "Nice" }))
      expect(client.comments.create(5, Body: "Nice").id).to eq(2)

      stub_request(:patch, "#{base}/fv-app/v2/Notes/5/Comments/2")
        .to_return(ok({ "CommentId" => { "Native" => 2 }, "IsEdited" => true }))
      expect(client.comments.update(5, 2, Body: "Edited").edited?).to be(true)
    end
  end

  describe "share_links (cursor pagination)" do
    it "auto-pages across the keyset cursor (ShareLinks/NewLastKey -> lastKey)" do
      stub_request(:get, "#{base}/fv-app/v2/ShareLinks")
        .with(query: { "limit" => "50" })
        .to_return(ok({ ShareLinks: [{ "LinkKey" => "k1" }], HasMore: true, NewLastKey: "k1" }))
      stub_request(:get, "#{base}/fv-app/v2/ShareLinks")
        .with(query: { "limit" => "50", "lastKey" => "k1" })
        .to_return(ok({ ShareLinks: [{ "LinkKey" => "k2" }], HasMore: false, NewLastKey: "k2" }))
      expect(client.share_links.list.map(&:key)).to eq(%w[k1 k2])
    end

    it "gets one link and batch-deletes with a bare array body" do
      stub_request(:get, "#{base}/fv-app/v2/ShareLinks/abc")
        .to_return(ok({ "LinkKey" => "abc", "ProjectID" => 7, "IsPasswordProtected" => true }))
      link = client.share_links.get("abc")
      expect([link.key, link.project_id, link.password_protected?]).to eq(["abc", 7, true])

      batch = stub_request(:post, "#{base}/fv-app/v2/ShareLinks/DeleteBatch")
              .with(body: %w[a b]).to_return(status: 204, body: "")
      expect(client.share_links.delete_batch(%w[a b])).to be(true)
      expect(batch).to have_been_made.once
    end
  end

  describe "reports" do
    it "lists saved reports and runs one (raw result set)" do
      items = [{ "ReportId" => { "Native" => 3 }, "Name" => "Aging" }]
      stub_request(:get, "#{base}/fv-app/v2/Reports")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: items, HasMore: false }))
      report = client.reports.list.first
      expect([report.id, report.name]).to eq([3, "Aging"])

      stub_request(:get, "#{base}/fv-app/v2/Reports/3")
        .with(query: { "limit" => "100" })
        .to_return(ok({ "Rows" => [{ "Col" => 1 }], "Total" => 1 }))
      expect(client.reports.run(3, limit: 100)).to eq({ "Rows" => [{ "Col" => 1 }], "Total" => 1 })
    end
  end
end
