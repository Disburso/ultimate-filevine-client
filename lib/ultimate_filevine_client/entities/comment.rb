# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A comment on a note (GET /fv-app/v2/Notes/{noteId}/Comments).
    class Comment < Base
      def id = native_id("CommentId")
      def note_id = native_id("NoteId")
      def project_id = native_id("ProjectId")
      def body = self["Body"]
      def author_id = native_id("AuthorId")
      def author_name = self["AuthorName"]
      def created_at = self["CreatedAt"]
      def edited? = self["IsEdited"] == true
    end
  end
end
