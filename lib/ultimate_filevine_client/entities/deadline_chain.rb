# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A project deadline chain (GET /fv-app/v2/projects/{id}/deadlinechains).
    # `visible_dates` and `main_date` stay as raw ChainDate hashes.
    class DeadlineChain < Base
      def id = native_id("DeadlineChainId")
      def name = self["Name"]
      def chain_type_id = native_id("ChainTypeId")
      def chain_type_name = self["ChainTypeName"]
      def jurisdiction = self["ChainTypeJurisdictionName"]
      def visible_dates = Array(self["VisibleDates"])
      def main_date = self["MainDate"]
    end
  end
end
