# frozen_string_literal: true

# Verifies the project-scoped billing delegators (client.project(id).…) bind the
# project id and hit the same paths as the org-level client.billing.* resources.
RSpec.describe "Project-scoped billing" do # rubocop:disable RSpec/DescribeClass
  subject(:client) { UltimateFilevineClient::Client.new(config:) }

  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:config) do
    UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "s", pat: "p", region: :us,
      org_id: "org-7", user_id: "user-9", token_store: store, retry_interval: 0
    )
  end
  let(:base) { "https://api.filevineapp.com" }
  let(:scope) { client.project(88) }

  before do
    store.write(config.token_key,
                UltimateFilevineClient::Auth::Token.new(value: "tok", expires_at: Time.now + 3600))
  end

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  it "exposes invoices bound to the project" do
    stub_request(:get, "#{base}/fv-app/v2/billingitem/projects/88/invoices")
      .with(query: { "limit" => "50", "offset" => "0" })
      .to_return(ok({ Items: [{ "InvoiceID" => 10 }], HasMore: false }))
    expect(scope.invoices.list.first.id).to eq(10)

    stub = stub_request(:post, "#{base}/fv-app/v2/projects/88/invoices").to_return(ok({ "InvoiceID" => 11 }))
    expect(scope.invoices.create(BillingItems: %w[g1]).id).to eq(11)
    expect(stub).to have_been_made.once
  end

  it "exposes billing_items bound to the project" do
    stub_request(:get, "#{base}/fv-app/v2/billingitem/projects/88")
      .with(query: { "limit" => "50", "offset" => "0" })
      .to_return(ok({ Items: [{ "ID" => "g1" }], HasMore: false }))
    expect(scope.billing_items.list.first.id).to eq("g1")
  end

  it "exposes funds bound to the project" do
    stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/funds")
      .to_return(ok({ "FundBalance" => 500.0 }))
    expect(scope.funds.balance).to eq({ "FundBalance" => 500.0 })
  end

  it "exposes transactions bound to the project" do
    stub = stub_request(:post, "#{base}/fv-app/v2/billing/projects/88/payment")
           .to_return(ok({ "TransactionID" => 500 }))
    expect(scope.transactions.create_payment(Total: 100).id).to eq(500)
    expect(stub).to have_been_made.once
  end

  it "exposes billing_settings and billing_vitals bound to the project" do
    stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/billingsettings")
      .to_return(ok({ "ProjectID" => 88 }))
    expect(scope.billing_settings.get).to eq({ "ProjectID" => 88 })

    stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/billingVitals")
      .to_return(ok({ "CurrentBalance" => 100.0 }))
    expect(scope.billing_vitals).to eq({ "CurrentBalance" => 100.0 })
  end
end
