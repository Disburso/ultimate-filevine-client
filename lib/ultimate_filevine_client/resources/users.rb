# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Users resource.
    #
    # Casing trap (verbatim from the spec): the org list and the current-user
    # endpoint use the capitalized /Users (and /Users/Me), while every per-user
    # read uses the lowercase /users/{userId}.
    class Users < Base
      LIST_PATH = "/fv-app/v2/Users"
      USER_PATH = "/fv-app/v2/users"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(LIST_PATH, Entities::User, limit:, **params)
      end

      # The current service-account / API user.
      def me = fetch_entity("#{LIST_PATH}/Me", Entities::User)
      def get(user_id) = fetch_entity("#{USER_PATH}/#{user_id}", Entities::User)
      def delete(user_id) = delete_path("#{USER_PATH}/#{user_id}")

      # Auto-paging task feed for a user (tasks are Note-backed).
      def tasks(user_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{USER_PATH}/#{user_id}/tasks", Entities::Task, limit:, **params)
      end

      # Auto-paging calendar items for a user.
      def appointments(user_id, limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities("#{USER_PATH}/#{user_id}/appointments", Entities::Appointment, limit:, **params)
      end

      # Auto-paging projects the user can access (raw UserProjectAccess hashes).
      def projects_access(user_id, limit: Pagination::DEFAULT_LIMIT, **params)
        paginate("#{USER_PATH}/#{user_id}/projects/access", params: params, limit: limit)
      end

      # The user's recent projects (a bare array, not paginated).
      def recent_projects(user_id, **params)
        body = connection.get("#{USER_PATH}/#{user_id}/recentprojects", params: params).body
        Array(body).map { |item| Entities::Project.new(item) }
      end
    end
  end
end
