# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's documents (/fv-app/v2/Projects/{projectId}/Documents).
    #
    # #list is the spec's deprecated per-project listing (prefer the org-level
    # client.documents with a project filter). #add attaches an EXISTING org
    # document to this project, optionally into a folder.
    class ProjectDocuments < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::Document, limit:, **params)
      end

      def add(document_id, folder_id: nil)
        params = folder_id.nil? ? nil : { folderId: folder_id }
        post_entity("#{base_path}/#{document_id}", Entities::Document, nil, params: params)
      end

      private

      def base_path = "/fv-app/v2/Projects/#{project_id}/Documents"
    end
  end
end
