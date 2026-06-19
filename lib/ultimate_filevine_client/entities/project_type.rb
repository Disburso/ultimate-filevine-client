# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine project type (GET /fv-app/v2/ProjectTypes).
    class ProjectType < Base
      def id = native_id("ProjectTypeId")
      def name = self["Name"]
    end
  end
end
