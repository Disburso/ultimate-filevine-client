# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's task feed (/fv-app/v2/projects/{projectId}/tasks). Tasks are
    # modeled as notes by Filevine; pin/unpin return the updated record.
    class ProjectTasks < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::Task, limit:, **params)
      end

      def pin(task_id) = post_entity("#{base_path}/#{task_id}/pin", Entities::Task)
      def unpin(task_id) = post_entity("#{base_path}/#{task_id}/unpin", Entities::Task)

      private

      def base_path = "/fv-app/v2/projects/#{project_id}/tasks"
    end
  end
end
