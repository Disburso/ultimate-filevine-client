# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Comments on notes (/fv-app/v2/Notes/{noteId}/Comments). Every call is
    # scoped to a note id (comments have no top-level collection).
    class Comments < Base
      def list(note_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path(note_id), Entities::Comment, limit:, **params)
      end

      def get(note_id, comment_id)
        fetch_entity("#{base_path(note_id)}/#{comment_id}", Entities::Comment)
      end

      def create(note_id, attributes)
        create_entity(base_path(note_id), Entities::Comment, attributes)
      end

      def update(note_id, comment_id, attributes)
        update_entity("#{base_path(note_id)}/#{comment_id}", Entities::Comment, attributes)
      end

      private

      def base_path(note_id) = "/fv-app/v2/Notes/#{note_id}/Comments"
    end
  end
end
