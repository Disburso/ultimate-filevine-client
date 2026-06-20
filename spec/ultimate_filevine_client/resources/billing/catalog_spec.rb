# frozen_string_literal: true

# Covers the org-level billing catalog resources: Rate Schedules, Invoice
# Templates, Billing Codes, FV Payments, and Timekeeper Classifications.
RSpec.describe "Billing catalog resources" do # rubocop:disable RSpec/DescribeClass
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

  def no_content = { status: 204, body: "" }

  describe "rate schedules" do
    it "lists (bare array), gets, creates, updates and deletes" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/org/rateschedules")
        .to_return(ok([{ "Id" => 1, "Name" => "Standard", "IsOrgDefault" => true }]))
      schedule = client.billing.rate_schedules.list.first
      expect(schedule).to be_a(UltimateFilevineClient::Entities::RateSchedule)
      expect([schedule.id, schedule.name, schedule.org_default?]).to eq([1, "Standard", true])

      stub_request(:get, "#{base}/fv-app/v2/rate-schedules/1").to_return(ok({ "RateScheduleId" => 1 }))
      expect(client.billing.rate_schedules.get(1).id).to eq(1)

      stub_request(:post, "#{base}/fv-app/v2/rate-schedules")
        .with(body: { Name: "New", TimeIncrement: 0.1, IsOrgDefault: false })
        .to_return(ok({ "RateScheduleId" => 2 }))
      expect(client.billing.rate_schedules.create(Name: "New", TimeIncrement: 0.1, IsOrgDefault: false).id).to eq(2)

      stub_request(:put, "#{base}/fv-app/v2/rate-schedules/2").to_return(ok({ "RateScheduleId" => 2 }))
      expect(client.billing.rate_schedules.update(2, Name: "Renamed").id).to eq(2)

      del = stub_request(:delete, "#{base}/fv-app/v2/rate-schedules/2").to_return(no_content)
      expect(client.billing.rate_schedules.delete(2)).to be(true)
      expect(del).to have_been_made.once
    end

    it "sets a project rate schedule and timekeeper details" do
      stub_request(:put, "#{base}/fv-app/v2/Billing/projects/88/rateschedule/1")
        .to_return(ok({ "Success" => true, "Message" => nil }))
      expect(client.billing.rate_schedules.set_for_project(88, 1)).to eq({ "Success" => true, "Message" => nil })

      tk = stub_request(:put, "#{base}/fv-app/v2/rate-schedules/timekeepers/9")
           .with(body: { RateScheduleIds: [1] }).to_return(no_content)
      expect(client.billing.rate_schedules.set_timekeeper(9, RateScheduleIds: [1])).to be(true)
      expect(tk).to have_been_made.once
    end

    it "creates, updates and deletes flat-fee templates" do
      stub_request(:post, "#{base}/fv-app/v2/rate-schedules/1/flatfeetemplates")
        .with(body: { Price: 100.0 }).to_return(ok({ "ID" => 5, "Price" => 100.0 }))
      expect(client.billing.rate_schedules.create_flat_fee_template(1, Price: 100.0)["ID"]).to eq(5)

      stub_request(:put, "#{base}/fv-app/v2/rate-schedules/1/flatfeetemplates/5")
        .to_return(ok({ "FlatFeeTemplate" => { "ID" => 5 } }))
      updated = client.billing.rate_schedules.update_flat_fee_template(1, 5, Price: 150.0)
      expect(updated["FlatFeeTemplate"]["ID"]).to eq(5)

      del = stub_request(:delete, "#{base}/fv-app/v2/rate-schedules/1/flatfeetemplates/5").to_return(no_content)
      expect(client.billing.rate_schedules.delete_flat_fee_template(1, 5)).to be(true)
      expect(del).to have_been_made.once
    end
  end

  describe "invoice templates" do
    it "lists (bare array), gets and CRUDs org templates" do
      stub_request(:get, "#{base}/fv-app/v2/billing/invoice-templates")
        .to_return(ok([{ "ID" => "t1", "Name" => "Default", "IsOrgDefault" => true, "DocID" => 7 }]))
      template = client.billing.invoice_templates.list.first
      expect(template).to be_a(UltimateFilevineClient::Entities::InvoiceTemplate)
      expect([template.id, template.name, template.doc_id, template.org_default?]).to eq(["t1", "Default", 7, true])

      stub_request(:get, "#{base}/fv-app/v2/billing/invoice-templates/t1")
        .to_return(ok({ "ID" => "t1", "Name" => "Default" }))
      expect(client.billing.invoice_templates.get("t1").name).to eq("Default")

      c = stub_request(:post, "#{base}/fv-app/v2/billing/invoice-templates")
          .with(body: { DocID: 7, Name: "Default" }).to_return(no_content)
      expect(client.billing.invoice_templates.create(DocID: 7, Name: "Default")).to be(true)
      expect(c).to have_been_made.once

      u = stub_request(:put, "#{base}/fv-app/v2/billing/invoice-templates/t1").to_return(no_content)
      expect(client.billing.invoice_templates.update("t1", Name: "Renamed")).to be(true)
      expect(u).to have_been_made.once

      d = stub_request(:delete, "#{base}/fv-app/v2/billing/invoice-templates/t1").to_return(no_content)
      expect(client.billing.invoice_templates.delete("t1")).to be(true)
      expect(d).to have_been_made.once
    end

    it "sets/unsets org and project defaults" do
      so = stub_request(:post, "#{base}/fv-app/v2/billing/invoice-templates/org-default/t1").to_return(no_content)
      expect(client.billing.invoice_templates.set_org_default("t1")).to be(true)
      expect(so).to have_been_made.once

      uo = stub_request(:put, "#{base}/fv-app/v2/billing/invoice-templates/unset-org-default").to_return(no_content)
      expect(client.billing.invoice_templates.unset_org_default).to be(true)
      expect(uo).to have_been_made.once

      stub_request(:get, "#{base}/fv-app/v2/billing/project/88/invoice-templates")
        .to_return(ok({ "ID" => "t1", "Name" => "Default" }))
      expect(client.billing.invoice_templates.project_default(88).id).to eq("t1")

      sp = stub_request(:put, "#{base}/fv-app/v2/billing/project/88/invoice-templates/t1").to_return(no_content)
      expect(client.billing.invoice_templates.set_project_default(88, "t1")).to be(true)
      expect(sp).to have_been_made.once

      up = stub_request(:delete, "#{base}/fv-app/v2/billing/project/88/invoice-templates").to_return(no_content)
      expect(client.billing.invoice_templates.unset_project_default(88)).to be(true)
      expect(up).to have_been_made.once
    end
  end

  describe "billing codes" do
    it "reads org and project code sets, and adds codes to a set" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/AvailableBillingCodes")
        .to_return(ok([{ "Id" => "set1", "Name" => "Time Codes" }]))
      expect(client.billing.codes.org.first["Id"]).to eq("set1")

      stub_request(:get, "#{base}/fv-app/v2/Billing/88/AvailableBillingCodes")
        .to_return(ok([{ "Id" => "set1" }]))
      expect(client.billing.codes.project(88).first["Id"]).to eq("set1")

      add = stub_request(:post, "#{base}/fv-app/v2/Billing/BillingCodeSet/set1/BillingCodes")
            .with(body: [{ Key: "K1", Description: "Research" }]).to_return(no_content)
      expect(client.billing.codes.add_to_set("set1", [{ Key: "K1", Description: "Research" }])).to be(true)
      expect(add).to have_been_made.once
    end
  end

  describe "FV payments" do
    it "reads invoice/project payment links and account mappings (raw)" do
      stub_request(:get, "#{base}/fv-app/v2/Billing/invoice/10/paymentlink")
        .to_return(ok({ "Success" => true, "Url" => "https://pay.example/10" }))
      expect(client.billing.fv_payments.invoice_payment_link(10)["Url"]).to eq("https://pay.example/10")

      stub_request(:get, "#{base}/fv-app/v2/billing/projects/88/payment-link")
        .to_return(ok({ "Success" => true, "Url" => "https://pay.example/p88" }))
      expect(client.billing.fv_payments.project_payment_link(88)["Url"]).to eq("https://pay.example/p88")

      stub_request(:get, "#{base}/fv-app/v2/billing/account-mappings")
        .to_return(ok({ "InvoicingAccount" => { "ID" => "a1" } }))
      expect(client.billing.fv_payments.account_mappings["InvoicingAccount"]["ID"]).to eq("a1")

      stub_request(:get, "#{base}/fv-app/v2/billing/account-mappings/list")
        .to_return(ok([{ "PaymentsAccountID" => "a1" }]))
      expect(client.billing.fv_payments.available_account_mappings.first["PaymentsAccountID"]).to eq("a1")

      stub_request(:get, "#{base}/fv-app/v2/billing/projects/88/account-mappings")
        .to_return(ok({ "ProjectFundsAccount" => { "ID" => "a2" } }))
      expect(client.billing.fv_payments.project_account_mappings(88)["ProjectFundsAccount"]["ID"]).to eq("a2")
    end
  end

  describe "timekeeper classifications" do
    it "lists the org classifications (raw)" do
      stub_request(:get, "#{base}/fv-app/v2/classifications")
        .to_return(ok([{ "ID" => 1, "Name" => "Partner" }]))
      expect(client.billing.timekeeper_classifications.list.first["Name"]).to eq("Partner")
    end
  end
end
