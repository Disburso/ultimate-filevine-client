# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine billing transaction (a payment or refund). `id` reads the plain
    # integer id ("ID" on get/list, "TransactionID" echoed by the write actions).
    class Transaction < Base
      def id = self["ID"] || self["TransactionID"]
      def project_id = self["ProjectID"]
      def date = self["Date"]
      def total = self["Total"]
      def source = self["Source"]
      def reference_number = self["ReferenceNumber"]
      def transaction_type = self["TransactionType"]
      def applied_balance = self["AppliedBalance"]
      def unapplied_balance = self["UnappliedBalance"]
      def void? = self["IsVoid"] == true
      def write_off? = self["IsWriteOff"] == true
    end
  end
end
