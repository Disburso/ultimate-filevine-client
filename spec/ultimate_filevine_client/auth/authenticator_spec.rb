# frozen_string_literal: true

require "uri"
require "concurrent/array"

RSpec.describe UltimateFilevineClient::Auth::Authenticator do
  subject(:authenticator) { described_class.new(config: config) }

  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:config) do
    UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "secret", pat: "pat-123", region: :us, token_store: store
    )
  end
  let(:token_url) { "https://identity.filevine.com/connect/token" }

  def stub_token(access_token: "tok-abc", expires_in: 3600, delay: 0.0)
    stub_request(:post, token_url).to_return do
      sleep(delay) if delay.positive?
      {
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { access_token: access_token, token_type: "Bearer", expires_in: expires_in }.to_json
      }
    end
  end

  it "mints a token and returns its value" do
    stub_token(access_token: "tok-abc")
    expect(authenticator.access_token).to eq("tok-abc")
    expect(a_request(:post, token_url)).to have_been_made.once
  end

  it "POSTs the gateway PAT grant with all required body fields" do
    stub_token
    authenticator.access_token

    matched = a_request(:post, token_url).with do |req|
      form = URI.decode_www_form(req.body).to_h
      form.values_at("grant_type", "client_id", "client_secret", "token") ==
        %w[personal_access_token cid secret pat-123] &&
        form["scope"].include?("fv.api.gateway.access")
    end
    expect(matched).to have_been_made.once
  end

  it "caches the token across calls (no second HTTP request)" do
    stub_token
    3.times { authenticator.access_token }
    expect(a_request(:post, token_url)).to have_been_made.once
  end

  it "re-mints after #invalidate!" do
    stub_token
    authenticator.access_token
    authenticator.invalidate!
    authenticator.access_token
    expect(a_request(:post, token_url)).to have_been_made.twice
  end

  it "wraps mint failures in AuthenticationError" do
    stub_request(:post, token_url).to_return(status: 401, body: "nope")
    expect { authenticator.access_token }
      .to raise_error(UltimateFilevineClient::AuthenticationError)
  end

  describe "single-flight under concurrency" do
    it "mints exactly once when many threads request a token simultaneously" do
      stub_token(access_token: "tok-shared", delay: 0.05)

      results = Concurrent::Array.new
      threads = Array.new(20) do
        Thread.new { results << authenticator.access_token }
      end
      threads.each(&:join)

      expect(results.to_a.uniq).to eq(["tok-shared"])
      expect(a_request(:post, token_url)).to have_been_made.once
    end
  end
end
