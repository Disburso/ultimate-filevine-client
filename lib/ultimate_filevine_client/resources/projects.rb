# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The Projects resource (/fv-app/v2/Projects). Casing matches the spec
    # verbatim (Filevine paths are case-sensitive) — note that some ops in this
    # family live under lowercase /projects while the core CRUD uses /Projects.
    class Projects < Base
      PATH = "/fv-app/v2/Projects"

      # Auto-paging list of {Entities::Project}. Pass `limit:` and any filter
      # params (e.g. requestedFields:). Lazy — iterate, .first, or .take(n).
      def list(limit: Pagination::DEFAULT_LIMIT, **params) = list_entities(PATH, Entities::Project, limit:, **params)

      # @param project_id [Integer, String] the Native project id
      def get(project_id) = fetch_entity("#{PATH}/#{project_id}", Entities::Project)
      def create(attributes) = create_entity(PATH, Entities::Project, attributes)
      def update(project_id, attributes) = update_entity("#{PATH}/#{project_id}", Entities::Project, attributes)

      # Archive (soft-delete) a project. Note the spec's lowercase /projects path
      # for this op (distinct from the capitalized PATH). Returns true on success.
      def archive(project_id) = delete_path("/fv-app/v2/projects/#{project_id}")

      # Bulk-remove a tag from the given projects. `project_ids` are Identifier
      # objects (e.g. { Native: 5 }). Returns nil on full success (204) or a
      # multi-status result hash when some projects fail (207).
      def remove_tag(tag_name, project_ids:)
        body = connection.delete("#{PATH}/tags/#{tag_name}", body: { ProjectIds: project_ids }).body
        body unless body.nil? || body == ""
      end

      # Apply a hashtag to a set of entities (projects/docs/notes/comments — each
      # an array of Identifier objects). Returns the {Entities::Hashtag} with its
      # updated usage counts. The hashtag itself is the path segment (no '#').
      def add_hashtag(hashtag, projects: nil, docs: nil, notes: nil, comments: nil)
        body = { Projects: projects, Docs: docs, Notes: notes, Comments: comments }.compact
        create_entity("/fv-app/v2/hashtags/#{hashtag}", Entities::Hashtag, body)
      end

      # Bulk-set each project's main client. `pairs` is an array of
      # { ProjectId: Identifier, PersonId: Identifier }. Returns true on success.
      def bulk_update_clients(pairs)
        perform_action(:put, "/fv-app/v2/projects/bulk", body: { ProjectPersonPairs: pairs })
      end

      # Run a conflict check against a project for `search_term`. Returns the raw
      # ConflictCheckApiModel ({ "Total", "Count", "Results" }). NOTE: not
      # idempotent — each call persists a new conflict-check record on the project.
      def conflict_check(project_id, search_term)
        connection.post("/fv-app/v2/Utils/conflictcheck/projects/#{project_id}",
                        params: { searchTerm: search_term }).body
      end
    end
  end
end
