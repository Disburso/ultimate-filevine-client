# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A billing rate schedule. The list endpoint returns a RateScheduleName
    # ({ Id, Name, IsOrgDefault }) while create/get/update echo a minimal
    # { RateScheduleId }; `id` reads whichever is present.
    class RateSchedule < Base
      def id = self["Id"] || self["RateScheduleId"] || self["ID"]
      def name = self["Name"]
      def time_increment = self["TimeIncrement"]
      def org_default? = self["IsOrgDefault"] == true
    end
  end
end
