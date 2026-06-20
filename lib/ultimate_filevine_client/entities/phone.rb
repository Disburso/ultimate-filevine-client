# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A contact phone number (GET /fv-app/v2/Contacts/{id}/phones).
    class Phone < Base
      def id = native_id("PhoneId")
      def number = self["Number"]
      def raw_number = self["RawNumber"]
      def extension = self["Extension"]
      def label = self["Label"]
      def smsable? = self["IsSmsable"] == true
      def faxable? = self["IsFaxable"] == true
    end
  end
end
