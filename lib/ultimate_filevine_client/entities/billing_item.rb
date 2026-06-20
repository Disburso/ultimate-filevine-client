# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine billing item (time / expense / flat-fee line). `id` is a string
    # GUID (the "ID" field on list/get, or "BillingItemId" echoed by create/update).
    class BillingItem < Base
      def id = self["ID"] || self["BillingItemId"]
      def project_id = self["ProjectID"]
      def org_id = self["OrgID"]
      def invoice_id = self["InvoiceID"]
      def billing_type = self["BillingType"]
      def date = self["Date"]
      def description = self["Description"]
      def rate = self["Rate"]
      def quantity = self["Quantity"]
      def billable? = self["IsBillable"] == true
      def chargeable? = self["IsChargeable"] == true
      def draft? = self["IsDraft"] == true
    end
  end
end
