# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # An org user / membership record (GET /fv-app/v2/Users). `id` is the
    # OrgUserId; the person's name lives under the nested "User" detail object.
    class User < Base
      def id = native_id("OrgUserId")
      def username = self["UserName"]
      def email = self["Email"]
      def active? = self["IsActive"] == true
      def created_at = self["CreatedDateTime"]
      def first_name = user_detail["FirstName"]
      def last_name = user_detail["LastName"]

      private

      def user_detail = self["User"] || {}
    end
  end
end
