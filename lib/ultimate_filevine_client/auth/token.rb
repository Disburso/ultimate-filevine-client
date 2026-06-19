# frozen_string_literal: true

require "time"

module UltimateFilevineClient
  module Auth
    # Refresh a token this many seconds before its real expiry, to avoid using
    # one that lapses mid-request.
    DEFAULT_TOKEN_SKEW = 60

    # Immutable bearer token with an absolute expiry time.
    #
    # The gateway PAT flow returns no refresh token, so "refresh" means re-mint;
    # this object only needs the value and when it goes stale.
    Token = Data.define(:value, :expires_at) do
      # Build from a parsed /connect/token response body.
      # @param body [Hash] string- or symbol-keyed
      def self.from_response(body, now: Time.now)
        access_token = body["access_token"] || body[:access_token]
        expires_in = body["expires_in"] || body[:expires_in]
        raise AuthenticationError, "token response missing access_token" if access_token.to_s.empty?

        new(value: access_token, expires_at: now + Integer(expires_in))
      end

      def expired?(now: Time.now, skew: DEFAULT_TOKEN_SKEW)
        now >= expires_at - skew
      end
    end
  end
end
