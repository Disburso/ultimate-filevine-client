# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A contact email address (GET /fv-app/v2/Contacts/{id}/emailaddresses).
    # `address` is the email string itself.
    class Email < Base
      def id = native_id("EmailId")
      def address = self["Address"]
      def label = self["Label"]
    end
  end
end
