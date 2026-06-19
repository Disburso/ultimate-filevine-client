# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine note (GET /fv-app/v2/Notes).
    class Note < Base
      def id = native_id("NoteId")
      def subject = self["Subject"]
      def body = self["Body"]
      def completed? = self["IsCompleted"] == true
    end
  end
end
