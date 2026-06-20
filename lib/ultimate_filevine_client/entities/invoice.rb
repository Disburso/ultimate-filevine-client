# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine invoice. The billing endpoints return several invoice shapes
    # (InvoiceListResponse on list/get, InvoiceIdResponse on create/update); `id`
    # reads whichever id field is present. Note billing ids are plain integers,
    # not Identifier objects.
    class Invoice < Base
      def id = self["InvoiceID"] || self["ID"]
      def number = self["InvoiceNumber"]
      def project_id = self["ProjectID"]
      def org_id = self["OrgID"]
      def description = self["Description"]
      def status = self["InvoiceStatus"]
      def total = self["Total"]
      def billable_total = self["BillableTotal"]
      def outstanding_balance = self["OutstandingBalance"]
      def invoice_date = self["InvoiceDate"]
      def due_date = self["DueDate"]
    end
  end
end
