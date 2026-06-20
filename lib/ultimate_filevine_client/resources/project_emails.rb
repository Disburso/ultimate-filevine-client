# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's emails (/fv-app/v2/projects/{projectId}/emails). Emails are
    # modeled as notes; #add posts a structured message (From is required),
    # #add_encoded posts the same message Base64-encoded.
    class ProjectEmails < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::Note, limit:, **params)
      end

      def add(message) = create_entity(base_path, Entities::Note, message)

      def add_encoded(base64_encoding)
        create_entity("/fv-app/v2/projects/#{project_id}/encodedEmails",
                      Entities::Note, { Base64Encoding: base64_encoding })
      end

      private

      def base_path = "/fv-app/v2/projects/#{project_id}/emails"
    end
  end
end
