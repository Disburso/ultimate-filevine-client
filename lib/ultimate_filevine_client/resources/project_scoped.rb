# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Base for sub-resources nested under a single project (e.g. a project's
    # deadlines). Carries the owning project id alongside the {Client}; each
    # subclass builds its own verbatim paths (Filevine paths are case-sensitive
    # and inconsistently cased, so they are never normalized here).
    class ProjectScoped < Base
      def initialize(client, project_id)
        super(client)
        @project_id = project_id
      end

      private

      attr_reader :project_id
    end
  end
end
