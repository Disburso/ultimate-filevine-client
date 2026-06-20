# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # A project's deadline chains.
    #
    # Casing trap (verbatim from the spec): create POSTs to the capitalized
    # /Projects/{id}/DeadlineChains, while list/get/update/delete use the
    # lowercase /projects/{id}/deadlinechains.
    class ProjectDeadlineChains < ProjectScoped
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(list_path, Entities::DeadlineChain, limit:, **params)
      end

      def get(chain_id) = fetch_entity("#{list_path}/#{chain_id}", Entities::DeadlineChain)
      def create(attributes) = create_entity(create_path, Entities::DeadlineChain, attributes)

      def update(chain_id, attributes)
        update_entity("#{list_path}/#{chain_id}", Entities::DeadlineChain, attributes)
      end

      def delete(chain_id) = delete_path("#{list_path}/#{chain_id}")

      # Update a single chain date; returns the full parent chain.
      def update_chain_date(chain_date_id, attributes)
        update_entity("/fv-app/v2/projects/#{project_id}/chaindates/#{chain_date_id}/update",
                      Entities::DeadlineChain, attributes)
      end

      private

      def list_path = "/fv-app/v2/projects/#{project_id}/deadlinechains"
      def create_path = "/fv-app/v2/Projects/#{project_id}/DeadlineChains"
    end
  end
end
