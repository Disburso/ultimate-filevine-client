# frozen_string_literal: true

require "tmpdir"
require "yaml"

# Guards the cassette scrubbing in spec/support/vcr.rb. Because sandbox cassettes
# are committed, a leak would publish real credentials — so this records a probe
# cassette built from the interactions a real read produces (token mint, the
# GetUserOrgsWithToken bootstrap, an authenticated GET) carrying known secrets,
# then asserts the written YAML (a) leaks no credential or token and (b) stays
# replay-safe (valid YAML, every response body still valid JSON). Recording
# through a real cassette runs the configured filters on eject. Offline.
RSpec.describe "sandbox cassette scrubbing" do # rubocop:disable RSpec/DescribeClass
  # Values that MUST be fully removed from the cassette.
  let(:creds) do
    { client_secret: "live-client-secret-BBB", pat: "live-pat-CCC", bearer: "live-bearer-DDD",
      org_token: "ORG-SCOPED-SECRET-EEE", cookie: "session-secret-FFF" }
  end
  # Tenant ids: masked in our request headers, but (numeric) left intact in bodies,
  # which is why the sandbox org must hold synthetic data.
  let(:tenant) { { org_id: "990011", user_id: "880022" } }

  around do |example|
    with_env("FILEVINE_CLIENT_ID" => "live-client-id-AAA",
             "FILEVINE_CLIENT_SECRET" => creds[:client_secret],
             "FILEVINE_PAT" => creds[:pat]) { example.run }
  end

  def with_env(vars)
    restore = vars.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    vars.each { |key, value| ENV[key] = value }
    yield
  ensure
    restore.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def interaction(request, status_body, status_headers)
    response = VCR::Response.new(VCR::ResponseStatus.new(200, "OK"), status_headers, status_body, "1.1")
    VCR::HTTPInteraction.new(request, response, Time.now)
  end

  def token_mint
    body = "grant_type=personal_access_token&client_secret=#{creds[:client_secret]}&token=#{creds[:pat]}"
    request = VCR::Request.new(:post, "https://identity.filevine.com/connect/token", body,
                               { "Content-Type" => ["application/x-www-form-urlencoded"] })
    interaction(request, { access_token: creds[:bearer], token_type: "Bearer", expires_in: 3600 }.to_json,
                { "Content-Type" => ["application/json"], "Set-Cookie" => ["s=#{creds[:cookie]}; HttpOnly"] })
  end

  # GetUserOrgsWithToken returns numeric tenant ids AND per-org bearer tokens.
  def user_orgs
    request = VCR::Request.new(:post, "https://api.filevineapp.com/fv-app/v2/utils/GetUserOrgsWithToken",
                               nil, { "Authorization" => ["Bearer #{creds[:bearer]}"] })
    body = { User: { UserId: tenant[:user_id].to_i },
             Orgs: [{ OrgId: tenant[:org_id].to_i, Token: creds[:org_token] }] }.to_json
    interaction(request, body, { "Content-Type" => ["application/json"] })
  end

  def authenticated_get
    request = VCR::Request.new(:get, "https://api.filevineapp.com/fv-app/v2/Users/Me", nil,
                               { "Authorization" => ["Bearer #{creds[:bearer]}"],
                                 "x-fv-orgid" => [tenant[:org_id]], "x-fv-userid" => [tenant[:user_id]] })
    interaction(request, { OrgUserId: { Native: 1 }, OwnerOrgId: tenant[:org_id].to_i }.to_json,
                { "Content-Type" => ["application/json"] })
  end

  def record_probe
    previous = VCR.configuration.cassette_library_dir
    Dir.mktmpdir do |dir|
      VCR.configuration.cassette_library_dir = dir
      cassette = VCR.insert_cassette("scrub_probe", record: :all)
      [token_mint, user_orgs, authenticated_get].each { |i| cassette.record_http_interaction(i) }
      VCR.eject_cassette
      File.read(File.join(dir, "scrub_probe.yml"))
    end
  ensure
    VCR.configuration.cassette_library_dir = previous
  end

  it "removes every credential, token, and cookie from the cassette" do
    yaml = record_probe
    creds.each_value { |secret| expect(yaml).not_to include(secret) }
  end

  it "masks the bearer and tenant ids in the request headers" do
    yaml = record_probe
    expect(yaml).to include("Bearer <BEARER_TOKEN>", "<FILEVINE_ORG_ID>", "<FILEVINE_USER_ID>")
  end

  it "blanks the token-exchange body and cans the token response" do
    yaml = record_probe
    expect(yaml).to include("[FILTERED token-exchange credentials]")
    expect(yaml).to include('"access_token":"<BEARER_TOKEN>"')
    expect(yaml).to include('"Token":"<REDACTED>"')
  end

  it "stays replay-safe: valid YAML with every response body still valid JSON" do
    cassette = YAML.safe_load(record_probe)
    bodies = cassette.fetch("http_interactions").map { |i| i.dig("response", "body", "string") }
    bodies.each { |body| expect { JSON.parse(body) }.not_to raise_error }
  end
end
