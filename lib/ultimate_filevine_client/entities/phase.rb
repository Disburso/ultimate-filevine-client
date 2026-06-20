# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A project type's phase (GET /fv-app/v2/ProjectTypes/{id}/phases). The
    # PhaseId is an Identifier object, so `id` unwraps its Native value.
    class Phase < Base
      def id = native_id("PhaseId")
      def name = self["Name"]
      def permanent? = self["IsPermanent"] == true
    end
  end
end
