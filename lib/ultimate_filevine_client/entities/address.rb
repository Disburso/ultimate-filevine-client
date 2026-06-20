# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A contact address (GET /fv-app/v2/Contacts/{id}/addresses).
    class Address < Base
      def id = native_id("AddressId")
      def line1 = self["Line1"]
      def line2 = self["Line2"]
      def city = self["City"]
      def state = self["State"]
      def postal_code = self["PostalCode"]
      def country = self["Country"]
      def label = self["Label"]
      def location_name = self["LocationName"]
      def full_address = self["FullAddress"]
    end
  end
end
