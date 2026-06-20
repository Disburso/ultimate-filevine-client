# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Project-scoped billing items, reached via
      # client.project(id).billing_items. Binds the project id and delegates to the
      # org-level client.billing.items resource.
      class ProjectBillingItems < ProjectScoped
        def list(**params) = billing.items.list(project_id:, **params)
        def get(billing_item_id) = billing.items.get(project_id, billing_item_id)
        def create(attributes) = billing.items.create(project_id, attributes)
        def update(billing_item_id, attributes) = billing.items.update(project_id, billing_item_id, attributes)

        private

        def billing = @client.billing
      end
    end
  end
end
