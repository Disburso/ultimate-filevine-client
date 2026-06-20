# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine task (GET /fv-app/v2/tasks). Tasks are feed items (Notes), so the
    # id may arrive as TaskId or (on most responses) NoteId, and the lifecycle
    # fields below mirror the Note shape the API returns from every task write.
    class Task < Base
      def id = native_id("TaskId") || native_id("NoteId")
      def subject = self["Subject"]
      def body = self["Body"]
      def project_id = native_id("ProjectId")
      def assignee_id = native_id("AssigneeId")
      def target_date = self["TargetDate"]
      def completed? = self["IsCompleted"] == true
      def pinned_to_feed? = self["IsPinnedToFeed"] == true
      def pinned_to_project? = self["IsPinnedToProject"] == true
    end
  end
end
