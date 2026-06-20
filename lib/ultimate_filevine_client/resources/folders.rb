# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Folders resource (/fv-app/v2/Folders). #structure walks the whole tree
    # for a project (projectId is required); #children pages one folder's
    # contents. #update may raise Conflict if a same-named sibling exists.
    class Folders < Base
      PATH = "/fv-app/v2/Folders"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(PATH, Entities::Folder, limit:, **params)
      end

      def get(folder_id) = fetch_entity("#{PATH}/#{folder_id}", Entities::Folder)
      def create(attributes) = create_entity(PATH, Entities::Folder, attributes)

      def update(folder_id, attributes)
        update_entity("#{PATH}/#{folder_id}", Entities::Folder, attributes)
      end

      def delete(folder_id) = delete_path("#{PATH}/#{folder_id}")

      def children(folder_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{PATH}/#{folder_id}/children", Entities::Folder, limit:, **params)
      end

      # Entire folder structure for a project (projectId is required by the API).
      def structure(project_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{PATH}/list", Entities::Folder, limit:, projectId: project_id, **params)
      end
    end
  end
end
