# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Contacts resource (/fv-app/v2/Contacts).
    class Contacts < Base
      PATH = "/fv-app/v2/Contacts"

      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Contact, limit:, **params)
      def get(contact_id) = fetch_entity("#{PATH}/#{contact_id}", Entities::Contact)
      def create(attributes) = create_entity(PATH, Entities::Contact, attributes)
      def update(contact_id, attributes) = update_entity("#{PATH}/#{contact_id}", Entities::Contact, attributes)
    end
  end
end
