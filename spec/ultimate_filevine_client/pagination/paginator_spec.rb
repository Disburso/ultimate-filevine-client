# frozen_string_literal: true

require "concurrent/array"

RSpec.describe UltimateFilevineClient::Pagination::Paginator do
  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:config) do
    UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "s", pat: "p", region: :us, token_store: store, retry_interval: 0
    )
  end
  let(:connection) do
    UltimateFilevineClient::Connection.new(
      config:, authenticator: UltimateFilevineClient::Auth::Authenticator.new(config:)
    )
  end
  let(:base) { "https://api.filevineapp.com" }

  before do
    store.write(config.token_key,
                UltimateFilevineClient::Auth::Token.new(value: "tok", expires_at: Time.now + 3600))
  end

  def page(items, has_more:)
    { status: 200, headers: { "Content-Type" => "application/json" },
      body: { Items: items, HasMore: has_more }.to_json }
  end

  it "auto-pages across HasMore, yielding wrapped items" do
    stub_request(:get, "#{base}/things").with(query: { "limit" => "2", "offset" => "0" })
                                        .to_return(page([{ "n" => 1 }, { "n" => 2 }], has_more: true))
    stub_request(:get, "#{base}/things").with(query: { "limit" => "2", "offset" => "2" })
                                        .to_return(page([{ "n" => 3 }], has_more: false))

    paginator = described_class.new(connection:, path: "/things", limit: 2) { |item| item["n"] }
    expect(paginator.to_a).to eq([1, 2, 3])
  end

  it "stops on an empty page" do
    stub_request(:get, "#{base}/things").with(query: { "limit" => "50", "offset" => "0" })
                                        .to_return(page([], has_more: true))
    expect(described_class.new(connection:, path: "/things").to_a).to eq([])
  end

  it "is lazy: .first fetches only the first page" do
    stub_request(:get, "#{base}/things").with(query: { "limit" => "50", "offset" => "0" })
                                        .to_return(page([{ "n" => 1 }, { "n" => 2 }], has_more: true))

    first = described_class.new(connection:, path: "/things") { |item| item["n"] }.first
    expect(first).to eq(1)
    # Only the first page is requested; the offset=2 page is never fetched.
    expect(a_request(:get, %r{#{Regexp.escape(base)}/things})).to have_been_made.once
  end

  it "runs an independent cursor per #each (safe to reuse / iterate concurrently)" do
    stub_request(:get, "#{base}/things").with(query: { "limit" => "2", "offset" => "0" })
                                        .to_return(page([{ "n" => 1 }, { "n" => 2 }], has_more: true))
    stub_request(:get, "#{base}/things").with(query: { "limit" => "2", "offset" => "2" })
                                        .to_return(page([{ "n" => 3 }], has_more: false))
    paginator = described_class.new(connection:, path: "/things", limit: 2) { |item| item["n"] }

    results = Concurrent::Array.new
    [paginator, paginator].map { |p| Thread.new { results << p.to_a } }.each(&:join)
    expect(results.to_a).to eq([[1, 2, 3], [1, 2, 3]])
  end
end
