# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Documents resource (/fv-app/v2/Documents).
    #
    # Note: uploading new document content is a multi-step flow (not covered by
    # #update); this resource handles metadata listing, fetching, updating, and
    # deletion.
    class Documents < Base
      PATH = "/fv-app/v2/Documents"

      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Document, limit:, **params)
      def get(document_id) = fetch_entity("#{PATH}/#{document_id}", Entities::Document)
      def update(document_id, attributes) = update_entity("#{PATH}/#{document_id}", Entities::Document, attributes)

      # @return [true] on success (a non-2xx response raises a RequestError).
      def delete(document_id)
        connection.delete("#{PATH}/#{document_id}")
        true
      end
    end
  end
end
