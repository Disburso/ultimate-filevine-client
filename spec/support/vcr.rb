# frozen_string_literal: true

require "vcr"
require_relative "sandbox"

VCR.configure do |config|
  config.cassette_library_dir = "spec/support/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # CI and the default suite never reach the live API: cassettes must already
  # exist and are replayed verbatim. A recording pass (FILEVINE_RECORD set + real
  # sandbox creds) is the only path that performs live requests — see
  # spec/recording/ and `rake record:sandbox`.
  config.default_cassette_options = {
    record: SandboxRecording.record_mode,
    # Match on the request shape, not on the scrubbed auth/tenant material, so
    # committed cassettes replay under dummy credentials.
    match_requests_on: %i[method path query]
  }

  # --- Keep every credential and token out of committed cassettes --------------
  #
  # NOTE on VCR's two filtering shapes (verified against VCR 6.4):
  #   * a value-only block (arity 0, e.g. reading ENV) masks that string EVERYWHERE
  #     in the interaction — request and response, headers and bodies.
  #   * a block taking the interaction (arity 1) masks only the REQUEST. So it is
  #     right for masking header values, but it CANNOT scrub a response body — those
  #     are handled in before_record below.

  # Static credentials, present only while recording. Strings, so masking them in a
  # JSON body (if they ever appeared in one) keeps the body valid.
  {
    "FILEVINE_CLIENT_ID" => "<FILEVINE_CLIENT_ID>",
    "FILEVINE_CLIENT_SECRET" => "<FILEVINE_CLIENT_SECRET>",
    "FILEVINE_PAT" => "<FILEVINE_PAT>"
  }.each do |env_key, placeholder|
    config.filter_sensitive_data(placeholder) { ENV.fetch(env_key, nil) }
  end

  # The bearer token, and the tenant ids, as they are SENT in request headers.
  # (The bearer in the token RESPONSE body is handled by the canned response in
  # before_record. Tenant ids are deliberately NOT masked in response bodies:
  # they are numeric there, so a string placeholder would produce invalid JSON and
  # break replay — hence the synthetic-data-only requirement for the sandbox org.)
  config.filter_sensitive_data("<BEARER_TOKEN>") do |interaction|
    authorization = interaction.request.headers["Authorization"]&.first
    authorization.split.last if authorization&.start_with?("Bearer ")
  end
  config.filter_sensitive_data("<FILEVINE_ORG_ID>") do |interaction|
    interaction.request.headers["x-fv-orgid"]&.first
  end
  config.filter_sensitive_data("<FILEVINE_USER_ID>") do |interaction|
    interaction.request.headers["x-fv-userid"]&.first
  end

  # Response-body scrubbing (which the filters above cannot reach):
  #   * the /connect/token exchange — blank the credential-bearing request form and
  #     replace the response with a canned body (keeps the minted token out, while
  #     staying parseable so replay still mints a token);
  #   * any other response — redact token-like JSON fields (e.g. the per-org tokens
  #     from GetUserOrgsWithToken), keeping the body valid JSON;
  #   * drop cookies, which can carry session material.
  token_field = /("[A-Za-z_]*[Tt]oken[A-Za-z_]*"\s*:\s*")[^"]*(")/
  config.before_record do |interaction|
    if interaction.request.uri.end_with?("/connect/token")
      interaction.request.body = "[FILTERED token-exchange credentials]"
      interaction.response.body = '{"access_token":"<BEARER_TOKEN>","token_type":"Bearer","expires_in":3600}'
    elsif interaction.response.body
      interaction.response.body = interaction.response.body.gsub(token_field, '\1<REDACTED>\2')
    end
    interaction.response.headers.reject! { |name, _| name.casecmp?("set-cookie") }
    interaction.request.headers.reject! { |name, _| name.casecmp?("cookie") }
  end

  # A recording pass needs real network; the default/replay run stays offline.
  WebMock.allow_net_connect! if SandboxRecording.recording?
end
