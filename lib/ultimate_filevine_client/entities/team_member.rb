# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A project team member (GET /fv-app/v2/projects/{id}/team). `id` is the
    # member's UserId. Note the field is "Fullname" (not "FullName") in the spec.
    class TeamMember < Base
      def id = native_id("UserId")
      def username = self["Username"]
      def email = self["Email"]
      def full_name = self["Fullname"]
      def level = self["Level"]
      def primary? = self["IsPrimary"] == true
      def admin? = self["IsAdmin"] == true
    end
  end
end
