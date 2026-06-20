# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Org-level teams (/fv-app/v2/teams). Project-scoped team membership lives on
    # client.project(id).team; this resource is the org team registry plus
    # team<->project assignment.
    #
    # Several writes are 204/no-content actions (return true); #create and #get
    # have no declared response schema, so they return the raw parsed body.
    class Teams < Base
      PATH = "/fv-app/v2/teams"

      # All teams in the org (the response is a bare array, not paginated).
      def list
        Array(connection.get(PATH).body).map { |item| Entities::Team.new(item) }
      end

      def get(team_id) = fetch_entity("#{PATH}/#{team_id}", Entities::Team)
      def create(attributes) = connection.post(PATH, body: attributes).body

      def add_members(team_id, attributes)
        perform_action(:put, "#{PATH}/#{team_id}/members", body: attributes)
      end

      def remove_members(team_id, attributes)
        perform_action(:post, "#{PATH}/#{team_id}/members/remove", body: attributes)
      end

      def assign_member_roles(team_id, attributes)
        perform_action(:put, "#{PATH}/#{team_id}/members/roles", body: attributes)
      end

      # Auto-paging list of projects the team can access (raw hashes).
      def projects_access(team_id, limit: Pagination::DEFAULT_LIMIT, **params)
        paginate("#{PATH}/#{team_id}/projects/access", params: params, limit: limit)
      end

      def add_project(team_id, project_id, apply_subscriptions: nil)
        params = apply_subscriptions.nil? ? nil : { applySubscriptions: apply_subscriptions }
        perform_action(:put, "#{PATH}/#{team_id}/projects/#{project_id}", params: params)
      end

      def remove_project(team_id, project_id)
        delete_path("#{PATH}/#{team_id}/projects/#{project_id}")
      end

      # Bulk-assign teams to projects (PUT /fv-app/v2/teamprojects).
      def assign_to_projects(attributes) = perform_action(:put, "/fv-app/v2/teamprojects", body: attributes)
    end
  end
end
