# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Project-scoped transactions (payments / refunds), reached via
      # client.project(id).transactions. Binds the project id and delegates to the
      # org-level client.billing.transactions resource.
      class ProjectTransactions < ProjectScoped
        def list(**params) = billing.transactions.list(project_id, **params)
        def create_payment(attributes) = billing.transactions.create_payment(project_id, attributes)
        def create_refund(attributes) = billing.transactions.create_refund(project_id, attributes)

        def update_payment(transaction_id, attributes)
          billing.transactions.update_payment(project_id, transaction_id, attributes)
        end

        def update_refund(transaction_id, attributes)
          billing.transactions.update_refund(project_id, transaction_id, attributes)
        end

        def void(transaction_id) = billing.transactions.void(project_id, transaction_id)

        private

        def billing = @client.billing
      end
    end
  end
end
