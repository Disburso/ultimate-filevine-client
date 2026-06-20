# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine hashtag with per-entity usage counts, returned when a hashtag is
    # applied to projects/docs/notes/comments (POST /fv-app/v2/hashtags/{hashtag}).
    class Hashtag < Base
      def name = self["Name"]
      def project_count = self["ProjectCount"]
      def doc_count = self["DocCount"]
      def note_count = self["NoteCount"]
      def comment_count = self["CommentCount"]
    end
  end
end
