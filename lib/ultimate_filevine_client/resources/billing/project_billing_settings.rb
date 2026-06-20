# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Project-scoped billing settings, reached via
      # client.project(id).billing_settings. Binds the project id and delegates to
      # the org-level client.billing.settings resource.
      class ProjectBillingSettings < ProjectScoped
        def get = billing.settings.get(project_id)
        def update(attributes) = billing.settings.update(project_id, attributes)
        def vitals = billing.settings.vitals(project_id)
        def fund_settings = billing.settings.fund_settings(project_id)
        def update_fund_settings(attributes) = billing.settings.update_fund_settings(project_id, attributes)
        def client_matter_id = billing.settings.client_matter_id(project_id)

        # rubocop:disable Naming/AccessorMethodName -- a write action, not an attribute writer
        def set_client_matter_id(client_matter_id)
          billing.settings.set_client_matter_id(project_id, client_matter_id)
        end
        # rubocop:enable Naming/AccessorMethodName

        private

        def billing = @client.billing
      end
    end
  end
end
