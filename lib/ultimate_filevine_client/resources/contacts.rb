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

      # --- Per-contact sub-lists (all auto-paging) ---

      def addresses(contact_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{PATH}/#{contact_id}/addresses", Entities::Address, limit:, **params)
      end

      # Note the spec's lowercase, run-together "emailaddresses" path segment.
      def emails(contact_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{PATH}/#{contact_id}/emailaddresses", Entities::Email, limit:, **params)
      end

      def phones(contact_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{PATH}/#{contact_id}/phones", Entities::Phone, limit:, **params)
      end

      # The projects this contact is on (ProjectContact membership records).
      def projects(contact_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{PATH}/#{contact_id}/projects", Entities::ProjectContact, limit:, **params)
      end

      # --- Reference data (raw) ---

      # A country-code => country-name map.
      def countries = connection.get("#{PATH}/Countries").body

      # The list of possible Contact.PrimaryLanguages values (array of strings).
      def primary_languages = connection.get("#{PATH}/PrimaryLanguages").body

      # Bulk-remove a tag from the given contacts. `person_ids` are Identifier
      # objects (e.g. { Native: 5 }). Returns true on success.
      def remove_tag(tag_name, person_ids:)
        connection.delete("#{PATH}/tags/#{tag_name}", body: { PersonIds: person_ids })
        true
      end
    end
  end
end
