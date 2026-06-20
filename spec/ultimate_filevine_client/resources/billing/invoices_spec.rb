# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Resources::Billing::Invoices do
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

  def invoice(id, **extra)
    { "InvoiceID" => id, "InvoiceNumber" => 1000 + id, "ProjectID" => 88,
      "InvoiceStatus" => "Draft" }.merge(extra.transform_keys(&:to_s))
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  def no_content = { status: 204, body: "" }

  describe "#list" do
    it "auto-pages the org invoice list under /billingitem/invoices" do
      stub_request(:get, "#{base}/fv-app/v2/billingitem/invoices")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [invoice(10), invoice(11)], HasMore: false }))
      invoices = client.billing.invoices.list.to_a
      expect(invoices).to all(be_a(UltimateFilevineClient::Entities::Invoice))
      expect(invoices.map(&:id)).to eq([10, 11])
    end

    it "lists a project's invoices under /billingitem/projects/{id}/invoices with filters" do
      stub = stub_request(:get, "#{base}/fv-app/v2/billingitem/projects/88/invoices")
             .with(query: { "limit" => "50", "offset" => "0", "status" => "Sent" })
             .to_return(ok({ Items: [invoice(10)], HasMore: false }))
      expect(client.billing.invoices.list(project_id: 88, status: "Sent").first.id).to eq(10)
      expect(stub).to have_been_made.once
    end
  end

  describe "#get" do
    it "fetches a single invoice" do
      stub_request(:get, "#{base}/fv-app/v2/billingitem/invoices/10")
        .to_return(ok(invoice(10, OutstandingBalance: 250.0)))
      result = client.billing.invoices.get(10)
      expect([result.id, result.number, result.outstanding_balance]).to eq([10, 1010, 250.0])
    end
  end

  describe "writes on a project" do
    it "creates an invoice (POST /projects/{id}/invoices)" do
      stub = stub_request(:post, "#{base}/fv-app/v2/projects/88/invoices")
             .with(body: { BillingItems: %w[g1 g2] }).to_return(ok({ "InvoiceID" => 10 }))
      expect(client.billing.invoices.create(88, BillingItems: %w[g1 g2]).id).to eq(10)
      expect(stub).to have_been_made.once
    end

    it "updates an invoice (PUT /projects/{id}/invoices/{invoiceId})" do
      stub = stub_request(:put, "#{base}/fv-app/v2/projects/88/invoices/10")
             .with(body: { Description: "Edited" }).to_return(ok({ "InvoiceID" => 10 }))
      expect(client.billing.invoices.update(88, 10, Description: "Edited").id).to eq(10)
      expect(stub).to have_been_made.once
    end

    it "deletes an invoice" do
      del = stub_request(:delete, "#{base}/fv-app/v2/projects/88/invoices/10").to_return(no_content)
      expect(client.billing.invoices.delete(88, 10)).to be(true)
      expect(del).to have_been_made.once
    end

    it "finalizes an invoice with a timezone offset (raw result)" do
      stub_request(:post, "#{base}/fv-app/v2/projects/88/invoices/10/finalize")
        .with(query: { "tzOffset" => "-300" }).to_return(ok({ "ID" => 10, "IsFinalized" => true }))
      expect(client.billing.invoices.finalize(88, 10, tz_offset: -300)).to eq({ "ID" => 10, "IsFinalized" => true })
    end
  end

  describe "lifecycle actions" do
    it "fetches the invoice PDF locator (raw)" do
      stub_request(:get, "#{base}/fv-app/v2/billing/invoices/10/pdf")
        .to_return(ok({ "Url" => "https://s3.example/inv.pdf", "ContentType" => "application/pdf" }))
      expect(client.billing.invoices.pdf(10)["Url"]).to eq("https://s3.example/inv.pdf")
    end

    it "updates description and status (returns the Invoice)" do
      stub_request(:put, "#{base}/fv-app/v2/billing/invoices/description")
        .with(body: { InvoiceID: 10, ProjectID: 88, Description: "New" })
        .to_return(ok(invoice(10, Description: "New")))
      updated = client.billing.invoices.update_description(invoice_id: 10, project_id: 88, description: "New")
      expect(updated.id).to eq(10)

      stub_request(:put, "#{base}/fv-app/v2/billing/invoices/status")
        .with(body: { InvoiceID: 10, ProjectID: 88, Status: "Sent" })
        .to_return(ok(invoice(10, InvoiceStatus: "Sent")))
      expect(client.billing.invoices.update_status(invoice_id: 10, project_id: 88, status: "Sent").status).to eq("Sent")
    end

    it "voids and writes off an invoice (204 -> true)" do
      v = stub_request(:put, "#{base}/fv-app/v2/billing/invoices/void")
          .with(body: { InvoiceID: 10, ProjectID: 88 }).to_return(no_content)
      expect(client.billing.invoices.void(invoice_id: 10, project_id: 88)).to be(true)
      expect(v).to have_been_made.once

      w = stub_request(:put, "#{base}/fv-app/v2/billing/invoices/writeoff")
          .with(body: { InvoiceID: 10, ProjectID: 88 }).to_return(no_content)
      expect(client.billing.invoices.write_off(invoice_id: 10, project_id: 88)).to be(true)
      expect(w).to have_been_made.once
    end

    it "approves, marks-as-sent (with offset) and sends-for-approval (204 -> true)" do
      a = stub_request(:post, "#{base}/fv-app/v2/billing/invoices/10/approve").to_return(no_content)
      expect(client.billing.invoices.approve(10)).to be(true)
      expect(a).to have_been_made.once

      m = stub_request(:post, "#{base}/fv-app/v2/billing/invoices/10/mark-as-sent")
          .with(query: { "timezoneOffset" => "-300" }).to_return(no_content)
      expect(client.billing.invoices.mark_as_sent(10, timezone_offset: -300)).to be(true)
      expect(m).to have_been_made.once

      s = stub_request(:post, "#{base}/fv-app/v2/billing/invoices/10/send-for-approval").to_return(no_content)
      expect(client.billing.invoices.send_for_approval(10)).to be(true)
      expect(s).to have_been_made.once
    end
  end
end
