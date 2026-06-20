# frozen_string_literal: true

require "faraday"

module UltimateFilevineClient
  # Performs raw byte transfers to/from absolute presigned (S3) URLs, outside the
  # Filevine gateway: no base URL, no auth/tenant headers, and no JSON middleware,
  # so request and response bodies pass through as raw bytes. Used by the document
  # upload/download flow. Safe to share across threads.
  class Transfer
    def initialize(config:)
      @connection = build_connection(config)
    end

    # PUT raw bytes to an absolute URL. Returns true; raises {TransferError} on a
    # non-2xx response, or {TimeoutError} on a timeout/connection failure.
    def put(url, body, content_type: nil)
      response = run do
        @connection.put(url) do |req|
          req.headers["Content-Type"] = content_type if content_type
          req.body = body
        end
      end
      ensure_success!(response, url)
      true
    end

    # GET raw bytes from an absolute URL. Returns the response body (a String of
    # bytes). Raises {TransferError} / {TimeoutError} on failure.
    def get(url)
      response = run { @connection.get(url) }
      ensure_success!(response, url)
      response.body
    end

    private

    def run
      yield
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
      raise TimeoutError, e.message
    end

    def ensure_success!(response, url)
      return if response.status < 400

      raise TransferError.new(status: response.status, url: url, body: response.body)
    end

    def build_connection(config)
      Faraday.new do |conn|
        conn.options.open_timeout = config.open_timeout
        conn.options.timeout = config.timeout
        conn.adapter config.adapter
      end
    end
  end
end
