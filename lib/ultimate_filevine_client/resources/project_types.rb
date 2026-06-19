# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Project Types resource (/fv-app/v2/ProjectTypes).
    class ProjectTypes < Base
      PATH = "/fv-app/v2/ProjectTypes"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(PATH, Entities::ProjectType, limit:, **params)
      end

      def get(project_type_id) = fetch_entity("#{PATH}/#{project_type_id}", Entities::ProjectType)

      # Auto-paging list of the project type's custom sections (raw hashes).
      def sections(project_type_id, limit: Pagination::DEFAULT_LIMIT, **params)
        paginate("#{PATH}/#{project_type_id}/sections", params: params, limit: limit)
      end
    end
  end
end
