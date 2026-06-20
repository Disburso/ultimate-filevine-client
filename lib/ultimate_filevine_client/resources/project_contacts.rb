# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's contacts (/fv-app/v2/Projects/{projectId}/contacts). Records are
    # the project<->contact links; #add expects an OrgContactId.
    class ProjectContacts < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(base_path, Entities::ProjectContact, limit:, **params)
      end

      def add(attributes) = create_entity(base_path, Entities::ProjectContact, attributes)

      def update(project_contact_id, attributes)
        update_entity("#{base_path}/#{project_contact_id}", Entities::ProjectContact, attributes)
      end

      def remove(project_contact_id) = delete_path("#{base_path}/#{project_contact_id}")

      private

      def base_path = "/fv-app/v2/Projects/#{project_id}/contacts"
    end
  end
end
