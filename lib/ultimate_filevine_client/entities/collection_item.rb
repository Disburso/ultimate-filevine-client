# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # A custom collection (sub-table) item
    # (GET /fv-app/v2/Projects/{id}/Collections/{selector}). The custom field
    # values live in the freeform #data (DataObject) bag.
    class CollectionItem < Base
      def id = native_id("ItemId")
      def data = self["DataObject"]
      def link = self["ItemLink"]
      def created_date = self["CreatedDate"]
    end
  end
end
