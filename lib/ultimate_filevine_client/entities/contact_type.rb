# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # An org contact type (GET /fv-app/v2/ContactTypes). Note: ContactTypeId is a
    # bare integer here (unlike most Filevine ids), which `native_id` passes through.
    class ContactType < Base
      def id = native_id("ContactTypeId")
      def name = self["Name"]
    end
  end
end
