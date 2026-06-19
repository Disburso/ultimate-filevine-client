# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine task (GET /fv-app/v2/tasks). Tasks are feed items, so the id may
    # arrive as TaskId or (in list responses) NoteId.
    class Task < Base
      def id = native_id("TaskId") || native_id("NoteId")
      def subject = self["Subject"]
      def body = self["Body"]
      def completed? = self["IsCompleted"] == true
    end
  end
end
