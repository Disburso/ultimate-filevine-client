# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Document share links (/fv-app/v2/ShareLinks). The list uses keyset/cursor
    # pagination (records under "ShareLinks", cursor "NewLastKey" -> "lastKey"),
    # not the standard offset/limit contract.
    class ShareLinks < Base
      PATH = "/fv-app/v2/ShareLinks"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        cursor_paginate(
          PATH,
          items_key: "ShareLinks", cursor_param: :lastKey, next_cursor_key: "NewLastKey",
          params: params, limit: limit
        ) { |item| Entities::ShareLink.new(item) }
      end

      def get(link_key) = fetch_entity("#{PATH}/#{link_key}", Entities::ShareLink)
      def delete(link_key) = delete_path("#{PATH}/#{link_key}")

      # Delete several links at once. Body is a bare JSON array of link keys.
      def delete_batch(link_keys)
        connection.post("#{PATH}/DeleteBatch", body: Array(link_keys))
        true
      end
    end
  end
end
