# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # An org team (GET /fv-app/v2/teams). `id` unwraps the ID Identifier; note
    # OrgID is a plain integer, not an Identifier.
    class Team < Base
      def id = native_id("ID")
      def org_id = self["OrgID"]
      def name = self["Name"]
      def description = self["Description"]
      def system_managed? = self["IsSystemManaged"] == true
      def member_count = self["MemberCount"]
    end
  end
end
