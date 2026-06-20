# frozen_string_literal: true

RSpec.describe UltimateFilevineClient::Connection do
  let(:store) { UltimateFilevineClient::TokenStore::MemoryStore.new }
  let(:base) { "https://api.filevineapp.com" }
  let(:token_url) { "https://identity.filevine.com/connect/token" }

  # Build a connection for a config (token store shared, retries instant by default).
  def build(seed: "tok-1", **overrides)
    config = UltimateFilevineClient::Configuration.new(
      client_id: "cid", client_secret: "secret", pat: "pat", region: :us,
      org_id: "org-7", user_id: "user-9", token_store: store, retry_interval: 0, **overrides
    )
    if seed
      store.write(config.token_key,
                  UltimateFilevineClient::Auth::Token.new(value: seed, expires_at: Time.now + 3600))
    end
    described_class.new(config:, authenticator: UltimateFilevineClient::Auth::Authenticator.new(config:))
  end

  def json(body, status: 200, headers: {})
    { status:, headers: { "Content-Type" => "application/json" }.merge(headers), body: body.to_json }
  end

  describe "header injection" do
    it "sends Authorization + tenant headers on every request" do
      stub = stub_request(:get, "#{base}/fv-app/v2/Projects")
             .with(headers: { "Authorization" => "Bearer tok-1", "x-fv-orgid" => "org-7", "x-fv-userid" => "user-9" })
             .to_return(json({ Items: [] }))
      build.get("/fv-app/v2/Projects")
      expect(stub).to have_been_made.once
    end

    it "stringifies integer org/user ids (as the bootstrap payload returns them)" do
      connection = build(org_id: 777, user_id: 555)
      stub = stub_request(:get, "#{base}/fv-app/v2/Projects")
             .with(headers: { "x-fv-orgid" => "777", "x-fv-userid" => "555" })
             .to_return(json({ Items: [] }))
      expect { connection.get("/fv-app/v2/Projects") }.not_to raise_error
      expect(stub).to have_been_made.once
    end

    it "omits org/user headers before they are resolved" do
      connection = build(org_id: nil, user_id: nil)
      stub_request(:post, "#{base}#{UltimateFilevineClient::Client::USER_ORGS_PATH}").to_return(json({ Orgs: [] }))
      connection.post(UltimateFilevineClient::Client::USER_ORGS_PATH)
      sent = a_request(:post, "#{base}#{UltimateFilevineClient::Client::USER_ORGS_PATH}")
             .with { |req| !req.headers.key?("X-Fv-Orgid") && !req.headers.key?("X-Fv-Userid") }
      expect(sent).to have_been_made.once
    end
  end

  describe "response handling" do
    it "returns a Response with the parsed JSON body" do
      stub_request(:get, "#{base}/fv-app/v2/Projects").to_return(json({ Items: [{ ProjectId: 1 }] }))
      response = build.get("/fv-app/v2/Projects")
      expect(response.status).to eq(200)
      expect(response.body["Items"].first["ProjectId"]).to eq(1)
    end

    it "passes query params through" do
      stub = stub_request(:get, "#{base}/fv-app/v2/Projects").with(query: { "limit" => "50", "offset" => "0" })
                                                             .to_return(json({ Items: [] }))
      build.get("/fv-app/v2/Projects", params: { limit: 50, offset: 0 })
      expect(stub).to have_been_made.once
    end
  end

  describe "error mapping" do
    {
      400 => UltimateFilevineClient::BadRequest,
      403 => UltimateFilevineClient::Forbidden,
      404 => UltimateFilevineClient::NotFound,
      409 => UltimateFilevineClient::Conflict,
      422 => UltimateFilevineClient::UnprocessableEntity
    }.each do |status, klass|
      it "maps HTTP #{status} to #{klass}" do
        stub_request(:get, "#{base}/x").to_return(json({ error: "no" }, status:))
        expect { build.get("/x") }.to raise_error(klass) { |e| expect(e.status).to eq(status) }
      end
    end

    it "maps 5xx to ServerError (after retries are exhausted)" do
      stub_request(:get, "#{base}/x").to_return(json({}, status: 503))
      expect { build.get("/x") }.to raise_error(UltimateFilevineClient::ServerError)
    end

    it "maps 429 to RateLimitError exposing Retry-After" do
      # max_retries: 0 so the Retry-After value is surfaced without sleeping.
      stub_request(:get, "#{base}/x").to_return(json({}, status: 429, headers: { "Retry-After" => "7" }))
      expect { build(max_retries: 0).get("/x") }
        .to raise_error(UltimateFilevineClient::RateLimitError) { |e| expect(e.retry_after).to eq("7") }
    end

    it "maps a 5xx with a malformed/mislabeled JSON body to ServerError (no Faraday::ParsingError leak)" do
      stub_request(:get, "#{base}/x")
        .to_return(status: 503, headers: { "Content-Type" => "application/json" }, body: "<html>502 Bad Gateway</html>")
      expect { build(max_retries: 0).get("/x") }
        .to raise_error(UltimateFilevineClient::ServerError) { |e| expect(e.status).to eq(503) }
    end

    it "returns the raw body (not a parse error) for a 2xx whose body is not valid JSON" do
      stub_request(:get, "#{base}/x")
        .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: "{ not json")
      response = build.get("/x")
      expect([response.status, response.body]).to eq([200, "{ not json"])
    end
  end

  describe "retry on transient failures" do
    it "retries idempotent GETs on 429 then succeeds" do
      stub_request(:get, "#{base}/x")
        .to_return(json({}, status: 429))
        .then.to_return(json({ ok: true }))
      response = build(max_retries: 2).get("/x")
      expect(response.status).to eq(200)
      expect(a_request(:get, "#{base}/x")).to have_been_made.twice
    end

    it "retries idempotent GETs on a 503 then succeeds" do
      stub_request(:get, "#{base}/x")
        .to_return(json({}, status: 503))
        .then.to_return(json({ ok: true }))
      response = build(max_retries: 2).get("/x")
      expect(response.status).to eq(200)
      expect(a_request(:get, "#{base}/x")).to have_been_made.twice
    end

    it "wraps timeouts in TimeoutError" do
      stub_request(:get, "#{base}/x").to_timeout
      expect { build(max_retries: 0).get("/x") }.to raise_error(UltimateFilevineClient::TimeoutError)
    end
  end

  # PUT/DELETE are HTTP-idempotent, but Filevine exposes non-idempotent ACTIONS
  # over them (fund void, AccountingSync, ...), so writes must NOT be auto-retried
  # — a transient 5xx after the action committed would otherwise double-apply it.
  describe "non-idempotent writes are not auto-retried" do
    %i[post patch put delete].each do |verb|
      it "issues a #{verb.upcase} exactly once on a 503 and raises ServerError" do
        stub_request(verb, "#{base}/x").to_return(json({}, status: 503))
        expect { build(max_retries: 3).public_send(verb, "/x") }
          .to raise_error(UltimateFilevineClient::ServerError)
        expect(a_request(verb, "#{base}/x")).to have_been_made.once
      end
    end
  end

  describe "401 handling" do
    it "re-mints the token once and retries the request" do
      connection = build(seed: "tok-1")
      stub_request(:post, token_url).to_return(json({ access_token: "tok-2", expires_in: 3600 }))
      unauthorized = stub_request(:get, "#{base}/x").with(headers: { "Authorization" => "Bearer tok-1" })
                                                    .to_return(json({}, status: 401))
      ok = stub_request(:get, "#{base}/x").with(headers: { "Authorization" => "Bearer tok-2" })
                                          .to_return(json({ ok: true }))

      response = connection.get("/x")
      expect(response.status).to eq(200)
      expect(unauthorized).to have_been_made.once
      expect(ok).to have_been_made.once
      expect(a_request(:post, token_url)).to have_been_made.once
    end

    it "raises Unauthorized if the retry still 401s" do
      connection = build(seed: "tok-1")
      stub_request(:post, token_url).to_return(json({ access_token: "tok-2", expires_in: 3600 }))
      stub_request(:get, "#{base}/x").to_return(json({}, status: 401))

      expect { connection.get("/x") }.to raise_error(UltimateFilevineClient::Unauthorized)
      expect(a_request(:get, "#{base}/x")).to have_been_made.twice
    end
  end
end
