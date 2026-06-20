# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A project fund transaction (deposit / retainer / debit / refund against a
    # project's trust funds). `id` is a string GUID.
    class ProjectFund < Base
      def id = self["ID"]
      def project_id = self["ProjectID"]
      def amount = self["Amount"]
      def fund_type = self["FundType"]
      def date = self["Date"]
      def reference_number = self["ReferenceNumber"]
      def source = self["Source"]
      def description = self["Description"]
      def payment_id = self["PaymentID"]
      def void? = self["IsVoided"] == true
    end
  end
end
