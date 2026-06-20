# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Project-scoped trust funds, reached via client.project(id).funds. Binds the
      # project id and delegates to the org-level client.billing.funds resource.
      class ProjectFunds < ProjectScoped
        def balance = billing.funds.balance(project_id)
        def list(**params) = billing.funds.list(project_id, **params)
        def get(fund_id) = billing.funds.get(project_id, fund_id)
        def create(attributes) = billing.funds.create(project_id, attributes)
        def void(fund_id) = billing.funds.void(project_id, fund_id)

        private

        def billing = @client.billing
      end
    end
  end
end
