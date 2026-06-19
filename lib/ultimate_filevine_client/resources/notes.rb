# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Notes resource (/fv-app/v2/Notes).
    class Notes < Base
      PATH = "/fv-app/v2/Notes"

      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Note, limit:, **params)
      def get(note_id) = fetch_entity("#{PATH}/#{note_id}", Entities::Note)
      def create(attributes) = create_entity(PATH, Entities::Note, attributes)
      def update(note_id, attributes) = update_entity("#{PATH}/#{note_id}", Entities::Note, attributes)
    end
  end
end
