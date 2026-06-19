# frozen_string_literal: true

module UltimateFilevineClient
  module Auth
    # Owns a single tenant's bearer-token lifecycle.
    #
    # Reads the current token from the configured {TokenStore}; on a miss or
    # expiry it mints a fresh one from the PAT. Minting is single-flight: a
    # per-instance Mutex with double-checked locking ensures that when many
    # threads need a token at once, exactly one HTTP mint happens and the rest
    # reuse the freshly stored token (no refresh stampede).
    class Authenticator
      GRANT_TYPE = "personal_access_token"
      TOKEN_PATH = "connect/token"

      def initialize(config:, connection: nil)
        @config = config
        @connection = connection # injectable Faraday connection to the identity host
        @mutex = Mutex.new
      end

      # @return [String] a valid bearer token value
      def access_token
        valid = stored_token
        return valid.value if valid

        @mutex.synchronize do
          valid = stored_token # double-checked: another thread may have just minted
          return valid.value if valid

          token = mint!
          store.write(token_key, token)
          token.value
        end
      end

      # Drop the cached token so the next call re-mints (e.g. after a 401).
      def invalidate!
        store.delete(token_key)
      end

      private

      def store
        @config.token_store
      end

      def token_key
        @config.token_key
      end

      def stored_token
        token = store.read(token_key)
        token if token && !token.expired?(skew: @config.token_expiry_skew)
      end

      def mint!
        response = identity_connection.post(TOKEN_PATH, token_request_params)
        Token.from_response(response.body)
      rescue Faraday::Error => e
        raise AuthenticationError, "Failed to mint Filevine token: #{e.message}"
      end

      def token_request_params
        {
          grant_type: GRANT_TYPE,
          client_id: @config.credentials.client_id,
          client_secret: @config.credentials.client_secret,
          scope: @config.scope,
          token: @config.credentials.pat
        }
      end

      def identity_connection
        @identity_connection ||= @connection || build_identity_connection
      end

      def build_identity_connection
        Faraday.new(url: @config.identity_base_url) do |conn|
          conn.options.open_timeout = @config.open_timeout
          conn.options.timeout = @config.timeout
          conn.request :url_encoded
          conn.response :json
          conn.response :raise_error
          conn.adapter @config.adapter
        end
      end
    end
  end
end
