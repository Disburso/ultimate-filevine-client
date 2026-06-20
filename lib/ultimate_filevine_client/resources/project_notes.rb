# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's note feed.
    #
    # Casing trap (verbatim from the spec): the list GET is the capitalized
    # /Projects/{id}/Notes, while pin/unpin POST to the lowercase
    # /projects/{id}/notes/{noteId}/(un)pin. Pin/unpin return the updated note.
    class ProjectNotes < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(list_path, Entities::Note, limit:, **params)
      end

      def pin(note_id) = post_entity("#{pin_base}/#{note_id}/pin", Entities::Note)
      def unpin(note_id) = post_entity("#{pin_base}/#{note_id}/unpin", Entities::Note)

      private

      def list_path = "/fv-app/v2/Projects/#{project_id}/Notes"
      def pin_base = "/fv-app/v2/projects/#{project_id}/notes"
    end
  end
end
