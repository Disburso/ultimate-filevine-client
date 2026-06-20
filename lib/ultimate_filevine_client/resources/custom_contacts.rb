# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Custom contacts (/fv-app/v2/Custom-Contacts). Writes use a delta/field-bag
    # model: `requests` is an array of update directives (each with an Action of
    # Update/Add/Remove/Reorder, a Selector, and a Value). Create/update return a
    # {Entities::Contact}; metadata and tab data are freeform raw hashes.
    class CustomContacts < Base
      PATH = "/fv-app/v2/Custom-Contacts"
      META_PATH = "/fv-app/v2/Custom-Contacts-Meta"

      # Contact field metadata — a bare array of field-info hashes.
      def meta(only_custom_fields: nil)
        params = only_custom_fields.nil? ? nil : { onlyCustomFields: only_custom_fields }
        connection.get(META_PATH, params: params).body
      end

      def create(contact_id, requests) = create_entity("#{PATH}/#{contact_id}", Entities::Contact, requests)
      def update(contact_id, requests) = update_entity("#{PATH}/#{contact_id}", Entities::Contact, requests)

      # A contact's custom-data tab — a freeform CustomData hash.
      def tab(contact_id, tab_id)
        connection.get("#{PATH}/#{contact_id}/Custom-Data/#{tab_id}").body
      end
    end
  end
end
