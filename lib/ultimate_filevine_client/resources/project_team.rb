# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's team (/fv-app/v2/projects/{projectId}/team). Members are keyed
    # by UserId. #teams returns the (un-paginated) list of teams on the project;
    # #org_roles auto-pages the project's org roles as raw hashes.
    class ProjectTeam < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::TeamMember, limit:, **params)
      end

      def add(attributes) = create_entity(base_path, Entities::TeamMember, attributes)
      def get(user_id) = fetch_entity("#{base_path}/#{user_id}", Entities::TeamMember)

      def update(user_id, attributes)
        update_entity("#{base_path}/#{user_id}", Entities::TeamMember, attributes)
      end

      def remove(user_id) = delete_path("#{base_path}/#{user_id}")

      def assign_roles(user_id, attributes)
        put_entity("#{base_path}/users/#{user_id}/roles", Entities::TeamMember, attributes)
      end

      # The teams assigned to this project (a bare array, not paginated).
      def teams = connection.get("/fv-app/v2/projects/#{project_id}/teams").body

      def org_roles(limit: Pagination::DEFAULT_LIMIT, **params)
        paginate("/fv-app/v2/projects/#{project_id}/teamorgroles", params: params, limit: limit)
      end

      private

      def base_path = "/fv-app/v2/projects/#{project_id}/team"
    end
  end
end
