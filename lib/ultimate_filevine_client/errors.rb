# frozen_string_literal: true

module UltimateFilevineClient
  # Raised when configuration or credentials are invalid, or a region is unknown.
  class ConfigurationError < Error; end

  # Raised when a bearer token cannot be minted from the Filevine identity service.
  class AuthenticationError < Error; end

  # Raised when a request times out, the connection fails, or another transport
  # /TLS error occurs (after retries) — i.e. any Faraday transport error that is
  # not an HTTP status response.
  class TimeoutError < Error; end

  # Raised when a direct byte transfer to/from a presigned (S3) URL fails. The
  # URL's query string (which carries the signature) is stripped from the
  # message and #url so credentials don't leak into logs.
  class TransferError < Error
    attr_reader :status, :url, :response_body

    def initialize(status:, url:, body: nil)
      @status = status
      @url = url.to_s.split("?").first
      @response_body = body
      super("Document transfer failed (HTTP #{status}) for #{@url}")
    end
  end

  # Base for errors mapped from a non-2xx HTTP response. Carries the status and
  # the raw response so callers can inspect details (Filevine publishes no formal
  # error-body schema, so the body shape is preserved as-is).
  class RequestError < Error
    attr_reader :status, :response_headers, :response_body

    def initialize(message = nil, status: nil, headers: nil, body: nil)
      @status = status
      @response_headers = headers
      @response_body = body
      super(message || "Filevine API request failed (HTTP #{status})")
    end
  end

  # 4xx and 5xx families.
  class ClientError < RequestError; end
  class ServerError < RequestError; end

  # Specific 4xx statuses (400, 401, 403, 404, 409, 422).
  class BadRequest < ClientError; end
  class Unauthorized < ClientError; end
  class Forbidden < ClientError; end
  class NotFound < ClientError; end
  class Conflict < ClientError; end
  class UnprocessableEntity < ClientError; end

  # 429 — exposes the Retry-After value when the server provides one.
  class RateLimitError < ClientError
    def retry_after
      response_headers && (response_headers["Retry-After"] || response_headers["retry-after"])
    end
  end

  STATUS_ERRORS = {
    400 => BadRequest,
    401 => Unauthorized,
    403 => Forbidden,
    404 => NotFound,
    409 => Conflict,
    422 => UnprocessableEntity,
    429 => RateLimitError
  }.freeze

  # Map an HTTP status (>= 400) to the most specific error class.
  def self.error_class_for(status)
    STATUS_ERRORS[status] || (status >= 500 ? ServerError : ClientError)
  end
end
