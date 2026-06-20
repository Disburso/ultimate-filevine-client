# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's static form section for one `selector`
    # (/fv-app/v2/Projects/{projectId}/Forms/{selector}). Obtain via
    # client.project(id).forms(selector). The form payload is freeform custom
    # field data, so #get/#update return and accept raw hashes.
    class ProjectForms < ProjectScoped
      def initialize(client, project_id, selector)
        super(client, project_id)
        @selector = selector
      end

      def get = connection.get(base_path).body
      def update(attributes) = connection.patch(base_path, body: attributes).body

      private

      def base_path = "/fv-app/v2/Projects/#{project_id}/Forms/#{@selector}"
    end
  end
end
