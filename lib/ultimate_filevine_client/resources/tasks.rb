# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Tasks resource. Note the lowercase path (/fv-app/v2/tasks) — Filevine
    # paths are case-sensitive and this family differs from /Projects etc.
    class Tasks < Base
      PATH = "/fv-app/v2/tasks"

      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Task, limit:, **params)
      def get(task_id) = fetch_entity("#{PATH}/#{task_id}", Entities::Task)
    end
  end
end
