# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's deadlines (/fv-app/v2/projects/{projectId}/deadlines).
    class ProjectDeadlines < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::Deadline, limit:, **params)
      end

      def get(deadline_id) = fetch_entity("#{base_path}/#{deadline_id}", Entities::Deadline)
      def create(attributes) = create_entity(base_path, Entities::Deadline, attributes)

      def update(deadline_id, attributes)
        update_entity("#{base_path}/#{deadline_id}", Entities::Deadline, attributes)
      end

      def delete(deadline_id) = delete_path("#{base_path}/#{deadline_id}")

      private

      def base_path = "/fv-app/v2/projects/#{project_id}/deadlines"
    end
  end
end
