# frozen_string_literal: true

# Covers the per-contact sub-lists (addresses / emails / phones / projects) plus
# the contact reference lists and bulk tag removal.
RSpec.describe "Contact sub-lists" do # rubocop:disable RSpec/DescribeClass
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

  def stub_list(path, items)
    stub_request(:get, "#{base}#{path}").with(query: { "limit" => "50", "offset" => "0" })
                                        .to_return(ok({ Items: items, HasMore: false }))
  end

  it "lists a contact's addresses" do
    stub_list("/fv-app/v2/Contacts/7/addresses",
              [{ "AddressId" => { "Native" => 1 }, "Line1" => "1 Main St", "City" => "Austin" }])
    address = client.contacts.addresses(7).first
    expect(address).to be_a(UltimateFilevineClient::Entities::Address)
    expect([address.id, address.line1, address.city]).to eq([1, "1 Main St", "Austin"])
  end

  it "lists a contact's email addresses (lowercase emailaddresses path)" do
    stub_list("/fv-app/v2/Contacts/7/emailaddresses",
              [{ "EmailId" => { "Native" => 2 }, "Address" => "jane@x.com", "Label" => "Work" }])
    email = client.contacts.emails(7).first
    expect(email).to be_a(UltimateFilevineClient::Entities::Email)
    expect([email.id, email.address, email.label]).to eq([2, "jane@x.com", "Work"])
  end

  it "lists a contact's phones" do
    stub_list("/fv-app/v2/Contacts/7/phones",
              [{ "PhoneId" => { "Native" => 3 }, "Number" => "(512) 555-0100", "IsSmsable" => true }])
    phone = client.contacts.phones(7).first
    expect([phone.id, phone.number, phone.smsable?]).to eq([3, "(512) 555-0100", true])
  end

  it "lists a contact's projects as ProjectContact memberships" do
    stub_list("/fv-app/v2/Contacts/7/projects",
              [{ "ProjectContactId" => { "Native" => 4 }, "Role" => "Plaintiff",
                 "Project" => { "ProjectName" => "Smith v. Acme" } }])
    pc = client.contacts.projects(7).first
    expect(pc).to be_a(UltimateFilevineClient::Entities::ProjectContact)
    expect([pc.id, pc.role]).to eq([4, "Plaintiff"])
  end

  it "returns the countries map and primary-languages list (raw)" do
    stub_request(:get, "#{base}/fv-app/v2/Contacts/Countries")
      .to_return(ok({ "US" => "United States", "CA" => "Canada" }))
    expect(client.contacts.countries).to eq({ "US" => "United States", "CA" => "Canada" })

    stub_request(:get, "#{base}/fv-app/v2/Contacts/PrimaryLanguages")
      .to_return(ok(%w[English Spanish]))
    expect(client.contacts.primary_languages).to eq(%w[English Spanish])
  end

  it "bulk-removes a tag from contacts via a DELETE with a body" do
    stub = stub_request(:delete, "#{base}/fv-app/v2/Contacts/tags/vip")
           .with(body: { "PersonIds" => [{ "Native" => 5 }] })
           .to_return(status: 204, body: "")
    expect(client.contacts.remove_tag("vip", person_ids: [{ Native: 5 }])).to be(true)
    expect(stub).to have_been_made.once
  end
end
