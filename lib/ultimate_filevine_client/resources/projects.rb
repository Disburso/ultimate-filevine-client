# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Projects resource (/fv-app/v2/Projects). Casing matches the spec
    # verbatim (Filevine paths are case-sensitive).
    class Projects < Base
      PATH = "/fv-app/v2/Projects"

      # Auto-paging list of {Entities::Project}. Pass `limit:` and any filter
      # params (e.g. requestedFields:). Lazy — iterate, .first, or .take(n).
      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Project, limit:, **params)

      # @param project_id [Integer, String] the Native project id
      def get(project_id) = fetch_entity("#{PATH}/#{project_id}", Entities::Project)
      def create(attributes) = create_entity(PATH, Entities::Project, attributes)
      def update(project_id, attributes) = update_entity("#{PATH}/#{project_id}", Entities::Project, attributes)
    end
  end
end
