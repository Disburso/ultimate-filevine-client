# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Resources::Billing::Transactions do
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

  def txn(id, **extra)
    { "ID" => id, "ProjectID" => 88, "Total" => 250.0, "TransactionType" => 1,
      "IsVoid" => false }.merge(extra.transform_keys(&:to_s))
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "reads (capitalized /Billing)" do
    it "auto-pages a project's transactions" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/transactions")
        .with(query: { "limit" => "50", "offset" => "0" })
        .to_return(ok({ Items: [txn(500), txn(501)], HasMore: false }))
      txns = client.billing.transactions.list(88).to_a
      expect(txns).to all(be_a(UltimateFilevineClient::Entities::Transaction))
      expect(txns.map(&:id)).to eq([500, 501])
    end

    it "gets a single transaction" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/transactions/500")
        .to_return(ok(txn(500, UnappliedBalance: 50.0)))
      result = client.billing.transactions.get(500)
      expect([result.id, result.total, result.unapplied_balance]).to eq([500, 250.0, 50.0])
    end
  end

  describe "payments and refunds (lowercase /billing)" do
    it "creates a payment" do
      attrs = { Date: "2026-07-01", Total: 250.0, Method: "Check", UseProjectFunds: false }
      stub = stub_request(:post, "#{base}/fv-app/v2/billing/projects/88/payment")
             .with(body: attrs).to_return(ok({ "TransactionID" => 500 }))
      expect(client.billing.transactions.create_payment(88, **attrs).id).to eq(500)
      expect(stub).to have_been_made.once
    end

    it "creates and applies a payment in one call" do
      stub_request(:post, "#{base}/fv-app/v2/billing/projects/88/payment/apply")
        .to_return(ok({ "TransactionID" => 500 }))
      expect(client.billing.transactions.create_and_apply_payment(88, Total: 100).id).to eq(500)
    end

    it "updates a payment" do
      stub = stub_request(:put, "#{base}/fv-app/v2/billing/projects/88/payment/500")
             .with(body: { Method: "Wire" }).to_return(ok({ "TransactionID" => 500 }))
      expect(client.billing.transactions.update_payment(88, 500, Method: "Wire").id).to eq(500)
      expect(stub).to have_been_made.once
    end

    it "creates and updates a refund" do
      stub_request(:post, "#{base}/fv-app/v2/billing/projects/88/refund")
        .to_return(ok({ "TransactionID" => 501 }))
      expect(client.billing.transactions.create_refund(88, Total: 50).id).to eq(501)

      stub_request(:put, "#{base}/fv-app/v2/billing/projects/88/refund/501")
        .to_return(ok({ "TransactionID" => 501 }))
      expect(client.billing.transactions.update_refund(88, 501, Description: "x").id).to eq(501)
    end
  end

  describe "voiding, unapplying and applying" do
    it "voids a transaction (DELETE returns the voided transaction)" do
      stub_request(:delete, "#{base}/fv-app/v2/billing/projects/88/transactions/500")
        .to_return(ok(txn(500, IsVoid: true)))
      result = client.billing.transactions.void(88, 500)
      expect([result.id, result.void?]).to eq([500, true])
    end

    it "unapplies a payment (DELETE with body -> true)" do
      stub = stub_request(:delete, "#{base}/fv-app/v2/billing/projects/88/unapply-payment")
             .with(body: { InvoiceID: 10, TransactionID: 500 }).to_return(status: 204, body: "")
      expect(client.billing.transactions.unapply_payment(88, invoice_id: 10, transaction_id: 500)).to be(true)
      expect(stub).to have_been_made.once
    end

    it "applies a payment transaction to an invoice for an amount (raw)" do
      stub_request(:put, "#{base}/fv-app/v2/Billing/invoices/10/transactions/500/100")
        .to_return(ok({ "AmountApplied" => 100.0 }))
      result = client.billing.transactions.apply_payment(invoice_id: 10, transaction_id: 500, amount: 100)
      expect(result).to eq({ "AmountApplied" => 100.0 })
    end
  end
end
