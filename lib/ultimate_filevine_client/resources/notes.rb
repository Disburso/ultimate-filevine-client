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

      # Move notes (and other activity items) to another project in the same org.
      # All ids are Identifier objects; `note_ids` accepts up to 100. Returns nil
      # on full success (204) or the multi-status result hash on partial failure.
      def move(note_ids:, source_project_id:, destination_project_id:)
        body = { SourceProjectId: source_project_id, DestinationProjectId: destination_project_id,
                 NoteIds: note_ids }
        bulk_request(:post, "#{PATH}/move", body: body)
      end

      # Bulk-remove a tag from the given notes. `note_ids` are Identifier objects.
      # Returns nil on full success (204) or the multi-status hash on a 207.
      def remove_tag(tag_name, note_ids:)
        bulk_request(:delete, "#{PATH}/tags/#{tag_name}", body: { NoteIds: note_ids })
      end

      # Pin / unpin a note to the current user's note feed (body-less POST;
      # returns the updated note). The project-feed variants live on
      # `client.project(id).notes.pin` / `.unpin`.
      def pin(note_id) = post_entity("#{PATH}/#{note_id}/pin", Entities::Note)
      def unpin(note_id) = post_entity("#{PATH}/#{note_id}/unpin", Entities::Note)
    end
  end
end
