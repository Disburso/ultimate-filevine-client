# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Projects resource (/fv-app/v2/Projects). Casing matches the spec
    # verbatim (Filevine paths are case-sensitive).
    class Projects < Base
      PATH = "/fv-app/v2/Projects"

      # Auto-paging list of {Entities::Project}. Pass `limit:` and any filter
      # params (e.g. requestedFields:). Lazy — iterate, .first, or .take(n).
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        paginate(PATH, params: params, limit: limit) { |item| Entities::Project.new(item) }
      end

      # @param project_id [Integer, String] the Native project id
      def get(project_id)
        Entities::Project.new(connection.get("#{PATH}/#{project_id}").body)
      end

      def create(attributes)
        Entities::Project.new(connection.post(PATH, body: attributes).body)
      end

      def update(project_id, attributes)
        Entities::Project.new(connection.patch("#{PATH}/#{project_id}", body: attributes).body)
      end
    end
  end
end
