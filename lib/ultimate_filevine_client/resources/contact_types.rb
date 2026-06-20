# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Org contact types (/fv-app/v2/ContactTypes).
    class ContactTypes < Base
      PATH = "/fv-app/v2/ContactTypes"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(PATH, Entities::ContactType, limit:, **params)
      end

      # Create a contact type with the given name; returns the new ContactType.
      def create(name) = create_entity(PATH, Entities::ContactType, { Name: name })
    end
  end
end
