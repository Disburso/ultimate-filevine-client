# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A Filevine contact/person (GET /fv-app/v2/Contacts).
    class Contact < Base
      def id = native_id("PersonId")
      def full_name = self["FullName"]
      def first_name = self["FirstName"]
      def last_name = self["LastName"]
      def primary_email = self["PrimaryEmail"]
    end
  end
end
