# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Images resource (/fv-app/v2/images/{imageId}) — fetch a stored image.
    #
    # By default Filevine returns a JSON envelope with the image base64-encoded
    # (the server's `asJson` default is true). Pass `as_json: false` to get the
    # raw image bytes instead; the response then carries the image content type
    # and is returned as an undecoded String.
    class Images < Base
      PATH = "/fv-app/v2/images"

      # @param image_id [String, Integer]
      # @param as_json [Boolean, nil] when false, returns raw image bytes; when
      #   true or omitted, returns the parsed JSON image envelope.
      # @return [Hash, String] the parsed envelope, or raw bytes when `as_json: false`
      def get(image_id, as_json: nil)
        params = {}
        params[:asJson] = as_json unless as_json.nil?
        connection.get("#{PATH}/#{image_id}", params: params).body
      end
    end
  end
end
