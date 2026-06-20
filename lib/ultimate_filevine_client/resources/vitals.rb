# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # The standalone Vitals endpoint (GET /fv-app/vitals — note: no `/v2`
    # segment, and the project is a required query param rather than a path
    # segment). Returns a single project's vitals payload.
    #
    # This is distinct from the project-scoped `client.project(id).vitals`,
    # which hits /fv-app/v2/Projects/{id}/Vitals and returns a raw array.
    class Vitals < Base
      PATH = "/fv-app/vitals"

      # @param project_id [Integer] the Native project id (required)
      # @param requested_fields [String, nil] optional comma-separated field projection
      # @return [Hash] the raw ProjectVital payload
      def get(project_id, requested_fields: nil)
        params = { projectId: project_id }
        params[:requestedFields] = requested_fields if requested_fields
        connection.get(PATH, params: params).body
      end
    end
  end
end
