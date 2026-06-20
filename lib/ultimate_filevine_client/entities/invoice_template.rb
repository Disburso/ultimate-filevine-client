# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # An invoice template (a document used to render invoices). `id` is a string
    # GUID; the template is backed by a document (DocID).
    class InvoiceTemplate < Base
      def id = self["ID"]
      def org_id = self["OrgID"]
      def doc_id = self["DocID"]
      def name = self["Name"]
      def description = self["Description"]
      def org_default? = self["IsOrgDefault"] == true
    end
  end
end
