# frozen_string_literal: true

# Covers the raw-response billing resources: Project Funds and Billing Settings.
RSpec.describe "Billing funds and settings" do # rubocop:disable RSpec/DescribeClass
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

  def ok(body)
    { status: 200, headers: { "Content-Type" => "application/json" }, body: body.to_json }
  end

  describe "funds" do
    it "reads the balance (raw)" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/funds")
        .to_return(ok({ "ProjectID" => 88, "FundBalance" => 1000.0 }))
      expect(client.billing.funds.balance(88)).to eq({ "ProjectID" => 88, "FundBalance" => 1000.0 })
    end

    it "creates a fund transaction (raw result with balance)" do
      stub = stub_request(:post, "#{base}/fv-app/v2/Billing/projects/88/funds")
             .with(body: { Amount: 500, FundType: 0 })
             .to_return(ok({ "ProjectFundTransaction" => { "ID" => "gf1" }, "FundBalance" => 1500.0 }))
      expect(client.billing.funds.create(88, Amount: 500, FundType: 0)["FundBalance"]).to eq(1500.0)
      expect(stub).to have_been_made.once
    end

    it "gets a single fund transaction (entity)" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/funds/gf1")
        .to_return(ok({ "ID" => "gf1", "ProjectID" => 88, "Amount" => 500.0, "FundType" => "Deposit" }))
      fund = client.billing.funds.get(88, "gf1")
      expect(fund).to be_a(UltimateFilevineClient::Entities::ProjectFund)
      expect([fund.id, fund.amount, fund.fund_type]).to eq(["gf1", 500.0, "Deposit"])
    end

    it "voids a fund transaction (raw result)" do
      stub_request(:put, "#{base}/fv-app/v2/Billing/projects/88/funds/gf1/void")
        .to_return(ok({ "FundBalance" => 1000.0 }))
      expect(client.billing.funds.void(88, "gf1")).to eq({ "FundBalance" => 1000.0 })
    end

    it "lists fund transactions as entities (bare ProjectFunds list, not auto-paged)" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/fundslist")
        .to_return(ok({ "Count" => 2, "ProjectFunds" => [{ "ID" => "gf1" }, { "ID" => "gf2" }] }))
      funds = client.billing.funds.list(88)
      expect(funds).to all(be_a(UltimateFilevineClient::Entities::ProjectFund))
      expect(funds.map(&:id)).to eq(%w[gf1 gf2])
    end
  end

  describe "settings" do
    it "reads org and project settings, and vitals (raw)" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/org/Settings").to_return(ok({ "IsBillingEnabled" => true }))
      expect(client.billing.settings.org).to eq({ "IsBillingEnabled" => true })

      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/billingsettings")
        .to_return(ok({ "ProjectID" => 88 }))
      expect(client.billing.settings.get(88)).to eq({ "ProjectID" => 88 })

      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/billingVitals")
        .to_return(ok({ "CurrentBalance" => 100.0, "ProjectFundsBalance" => 50.0 }))
      expect(client.billing.settings.vitals(88)["CurrentBalance"]).to eq(100.0)
    end

    it "updates project settings (hyphenated path, raw result)" do
      stub = stub_request(:put, "#{base}/fv-app/v2/Billing/projects/88/billing-settings")
             .with(body: { DefaultTermsID: 3 }).to_return(ok({ "Success" => true }))
      expect(client.billing.settings.update(88, DefaultTermsID: 3)).to eq({ "Success" => true })
      expect(stub).to have_been_made.once
    end

    it "reads and sets the client/matter id" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/projectbillingsettings/88/clientMatterId")
        .to_return(ok("ABC-123"))
      expect(client.billing.settings.client_matter_id(88)).to eq("ABC-123")

      stub = stub_request(:post, "#{base}/fv-app/v2/Billing/projectbillingsettings/88/clientMatterId")
             .with(query: { "clientMatterId" => "ABC-123" }).to_return(ok(true))
      expect(client.billing.settings.set_client_matter_id(88, "ABC-123")).to be(true)
      expect(stub).to have_been_made.once
    end

    it "reads and updates fund settings (raw)" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/projects/88/projectFundSettings")
        .to_return(ok({ "InitialFunds" => 1000.0, "CanEdit" => true }))
      expect(client.billing.settings.fund_settings(88)["CanEdit"]).to be(true)

      stub = stub_request(:put, "#{base}/fv-app/v2/Billing/projects/88/projectFundSettings")
             .with(body: { FundsThreshold: 200.0 }).to_return(ok({ "FundsThreshold" => 200.0 }))
      expect(client.billing.settings.update_fund_settings(88, FundsThreshold: 200.0)["FundsThreshold"]).to eq(200.0)
      expect(stub).to have_been_made.once
    end
  end
end
