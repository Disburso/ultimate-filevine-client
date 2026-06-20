# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Resources::Billing::Items do
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

  def item(id, **extra)
    { "ID" => id, "ProjectID" => 88, "BillingType" => "Time", "Rate" => 250.0,
      "Quantity" => 2.0, "IsBillable" => true, "IsDraft" => false }.merge(extra.transform_keys(&:to_s))
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "#list" do
    it "auto-pages org billing items under /billingitem/org" do
      stub_request(:get, "#{base}/fv-app/v2/billingitem/org")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [item("g1"), item("g2")], HasMore: false }))
      items = client.billing.items.list.to_a
      expect(items).to all(be_a(UltimateFilevineClient::Entities::BillingItem))
      expect(items.map(&:id)).to eq(%w[g1 g2])
      expect(items.first.billable?).to be(true)
    end

    it "lists a project's billing items under /billingitem/projects/{id} with filters" do
      stub = stub_request(:get, "#{base}/fv-app/v2/billingitem/projects/88")
             .with(query: { "limit" => "50", "offset" => "0", "billingType" => "Time" })
             .to_return(ok({ Items: [item("g1")], HasMore: false }))
      expect(client.billing.items.list(project_id: 88, billingType: "Time").first.id).to eq("g1")
      expect(stub).to have_been_made.once
    end
  end

  describe "#get" do
    it "fetches a single project billing item under /billing/projects/{id}/billing-items/{itemId}" do
      stub_request(:get, "#{base}/fv-app/v2/billing/projects/88/billing-items/g1")
        .to_return(ok(item("g1", Description: "Drafting")))
      result = client.billing.items.get(88, "g1")
      expect([result.id, result.description, result.rate]).to eq(["g1", "Drafting", 250.0])
    end
  end

  describe "writes" do
    it "creates a billing item (POST /projects/{id}/BillingItem)" do
      attrs = { BillingType: "Time", IsBillable: true, Date: "2026-07-01", Description: "Work", Quantity: 1.0 }
      stub = stub_request(:post, "#{base}/fv-app/v2/projects/88/BillingItem")
             .with(body: attrs).to_return(ok({ "BillingItemId" => "g9" }))
      expect(client.billing.items.create(88, **attrs).id).to eq("g9")
      expect(stub).to have_been_made.once
    end

    it "updates a billing item (PUT /projects/{id}/BillingItem/{itemId})" do
      stub = stub_request(:put, "#{base}/fv-app/v2/projects/88/BillingItem/g1")
             .with(body: { Description: "Edited" }).to_return(ok({ "BillingItemId" => "g1" }))
      expect(client.billing.items.update(88, "g1", Description: "Edited").id).to eq("g1")
      expect(stub).to have_been_made.once
    end

    it "deletes a billing item under /Billing/Delete/BillingItem/{itemId}" do
      del = stub_request(:delete, "#{base}/fv-app/v2/Billing/Delete/BillingItem/g1").to_return(status: 204, body: "")
      expect(client.billing.items.delete("g1")).to be(true)
      expect(del).to have_been_made.once
    end
  end

  describe "notes and attachments (204 -> true)" do
    it "sets and removes a note" do
      s = stub_request(:put, "#{base}/fv-app/v2/billingitem/g1/note")
          .with(body: { ProjectID: 88, NoteID: 5 }).to_return(status: 204, body: "")
      expect(client.billing.items.set_note("g1", project_id: 88, note_id: 5)).to be(true)
      expect(s).to have_been_made.once

      r = stub_request(:delete, "#{base}/fv-app/v2/billingitem/88/note/g1").to_return(status: 204, body: "")
      expect(client.billing.items.remove_note(88, "g1")).to be(true)
      expect(r).to have_been_made.once
    end

    it "adds and removes attachments" do
      a = stub_request(:post, "#{base}/fv-app/v2/billingitems/g1/attachments")
          .with(body: { ProjectID: 88, DocIDs: [3, 4] }).to_return(status: 204, body: "")
      expect(client.billing.items.add_attachments("g1", project_id: 88, doc_ids: [3, 4])).to be(true)
      expect(a).to have_been_made.once

      r = stub_request(:delete, "#{base}/fv-app/v2/billingitems/g1/attachments")
          .with(body: { ProjectID: 88, DocIDs: [3] }).to_return(status: 204, body: "")
      expect(client.billing.items.remove_attachments("g1", project_id: 88, doc_ids: 3)).to be(true)
      expect(r).to have_been_made.once
    end
  end

  describe "#accounting_sync" do
    it "PUTs the sync entries and returns the raw status" do
      stub_request(:put, "#{base}/fv-app/v2/AccountingSync")
        .with(body: [{ BillingItemId: "g1", SyncSuccessful: true }])
        .to_return(ok(200))
      expect(client.billing.items.accounting_sync([{ BillingItemId: "g1", SyncSuccessful: true }])).to eq(200)
    end
  end
end
