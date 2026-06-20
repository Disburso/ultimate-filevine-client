# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A saved report (GET /fv-app/v2/Reports). Running one (Reports#run) returns
    # the raw, untyped result set rather than a Report.
    class Report < Base
      def id = native_id("ReportId")
      def name = self["Name"]
    end
  end
end
