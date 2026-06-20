# frozen_string_literal: true

require "faraday"
require "faraday/retry"

module UltimateFilevineClient
  # Per-tenant HTTP connection to the Filevine gateway.
  #
  # On every request it injects the bearer token (from the {Auth::Authenticator})
  # plus the tenant headers (x-fv-orgid / x-fv-userid). It retries idempotent
  # 429/5xx responses (honoring Retry-After), maps error statuses to the gem's
  # exception hierarchy, and transparently re-mints the token once on a 401.
  #
  # The underlying Faraday connection is built eagerly and shared across threads.
  class Connection
    RETRYABLE_STATUSES = [429, 500, 502, 503, 504].freeze
    HTTP_METHODS = %i[get post put patch delete].freeze

    def initialize(config:, authenticator:)
      @config = config
      @authenticator = authenticator
      @faraday = build_connection
    end

    HTTP_METHODS.each do |verb|
      define_method(verb) do |path, body: nil, params: nil, headers: {}|
        request(verb, path, body: body, params: params, headers: headers)
      end
    end

    # @return [Response]
    def request(method, path, body: nil, params: nil, headers: {})
      execute(method, path, body, params, headers)
    rescue Unauthorized
      # Token may have been revoked/rotated; drop it and retry exactly once.
      @authenticator.invalidate!
      execute(method, path, body, params, headers)
    end

    private

    def execute(method, path, body, params, headers)
      response = perform(method, path, body, params, headers)
      raise_on_error(response)
      Response.new(status: response.status, headers: response.headers, body: response.body)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise TimeoutError, e.message
    end

    def perform(method, path, body, params, headers)
      @faraday.public_send(method, path) do |req|
        req.params.update(params) if params && !params.empty?
        request_headers(headers).each { |key, value| req.headers[key] = value }
        req.body = body unless body.nil?
      end
    end

    def raise_on_error(response)
      return if response.status < 400

      error = UltimateFilevineClient.error_class_for(response.status)
                                    .new(status: response.status, headers: response.headers, body: response.body)
      raise error
    end

    def request_headers(extra)
      {
        "Authorization" => "Bearer #{@authenticator.access_token}",
        # Coerce to String: the bootstrap payload often carries org/user ids as
        # JSON integers, and Faraday calls #strip on header values. `&.to_s` keeps
        # a nil (still-unresolved) id nil, so `compact` drops it.
        "x-fv-orgid" => @config.org_id&.to_s,
        "x-fv-userid" => @config.user_id&.to_s
      }.compact.merge(extra)
    end

    def build_connection
      Faraday.new(url: @config.api_base_url) do |conn|
        conn.options.open_timeout = @config.open_timeout
        conn.options.timeout = @config.timeout
        conn.request :json
        conn.request :retry, retry_options
        conn.response :json, content_type: /\bjson$/
        conn.adapter @config.adapter
      end
    end

    def retry_options
      {
        max: @config.max_retries,
        interval: @config.retry_interval,
        backoff_factor: 2,
        retry_statuses: RETRYABLE_STATUSES
        # `methods` left at faraday-retry's idempotent default, so POST/PATCH are
        # not auto-retried (avoids double-writes); callers handle their 429/5xx.
      }
    end
  end
end
