# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine project (GET /fv-app/v2/Projects). Field names mirror the spec;
    # `id` unwraps the ProjectId Identifier to its Native integer.
    class Project < Base
      def id = native_id("ProjectId")
      def name = self["ProjectName"]
      def number = self["Number"]
      def client_name = self["ClientName"]
      def phase = self["PhaseName"]
      def project_type_code = self["ProjectTypeCode"]
      def archived? = self["IsArchived"] == true
    end
  end
end
