# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's custom collection (sub-table) for one section `selector`
    # (/fv-app/v2/Projects/{projectId}/Collections/{selector}). Obtain via
    # client.project(id).collections(selector). Custom field values live in the
    # freeform DataObject of each {Entities::CollectionItem}.
    class ProjectCollections < ProjectScoped
      def initialize(client, project_id, selector)
        super(client, project_id)
        @selector = selector
      end

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::CollectionItem, limit:, **params)
      end

      def get(unique_id) = fetch_entity("#{base_path}/#{unique_id}", Entities::CollectionItem)
      def create(attributes) = create_entity(base_path, Entities::CollectionItem, attributes)

      def update(unique_id, attributes)
        update_entity("#{base_path}/#{unique_id}", Entities::CollectionItem, attributes)
      end

      def delete(unique_id) = delete_path("#{base_path}/#{unique_id}")

      private

      def base_path = "/fv-app/v2/Projects/#{project_id}/Collections/#{@selector}"
    end
  end
end
