# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A contact linked to a project (GET /fv-app/v2/Projects/{id}/contacts).
    # `id` is the link id (ProjectContactId); the underlying org contact is
    # available via #org_contact_id or the embedded #org_contact.
    class ProjectContact < Base
      def id = native_id("ProjectContactId")
      def project_id = native_id("ProjectId")
      def org_contact_id = native_id("OrgContactId")
      def role = self["Role"]

      # The embedded org contact, when the response includes it.
      def org_contact
        raw = self["OrgContact"]
        raw && Contact.new(raw)
      end
    end
  end
end
