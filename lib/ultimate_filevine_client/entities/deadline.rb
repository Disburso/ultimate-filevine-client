# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A project deadline (GET /fv-app/v2/projects/{id}/deadlines).
    class Deadline < Base
      def id = native_id("DeadlineId")
      def project_id = native_id("ProjectId")
      def name = self["Name"]
      def notes = self["Notes"]
      def due_date = self["DueDate"]
      def done_date = self["DoneDate"]
      def completed? = !self["DoneDate"].nil?
    end
  end
end
