# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A deadline chain type (GET /fv-app/v2/chaintypes). Unlike ContactType, the
    # ChainTypeId here IS an Identifier object, so `id` unwraps its Native value.
    class ChainType < Base
      def id = native_id("ChainTypeId")
      def name = self["Name"]
      def active? = self["IsActive"] == true
      def can_be_removed? = self["CanBeRemoved"] == true
      def jurisdiction_id = native_id("JurisdictionId")
      def jurisdiction_name = self["JurisdictionName"]
    end
  end
end
