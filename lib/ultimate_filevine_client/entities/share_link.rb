# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A document share link (GET /fv-app/v2/ShareLinks). Identified by a plain
    # string `key` (LinkKey), not an Identifier object; ProjectID is a plain int.
    class ShareLink < Base
      def key = self["LinkKey"]
      def id = key
      def project_id = self["ProjectID"]
      def expiration_date = self["ExpirationDate"]
      def days_left = self["DaysLeft"]
      def created_at = self["CreatedAtDate"]
      def password_protected? = self["IsPasswordProtected"] == true
    end
  end
end
