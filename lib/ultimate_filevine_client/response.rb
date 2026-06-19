# frozen_string_literal: true

module UltimateFilevineClient
  # A successful HTTP response: status, headers (case-insensitive Faraday object),
  # and the parsed JSON body. Returned by {Connection} request methods.
  Response = Data.define(:status, :headers, :body)
end
