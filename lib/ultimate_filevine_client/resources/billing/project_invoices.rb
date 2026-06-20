# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Project-scoped invoices, reached via client.project(id).invoices. A focused
      # convenience view that binds the project id and delegates to the org-level
      # client.billing.invoices resource.
      class ProjectInvoices < ProjectScoped
        def list(**params) = billing.invoices.list(project_id:, **params)
        def get(invoice_id) = billing.invoices.get(invoice_id)
        def create(attributes) = billing.invoices.create(project_id, attributes)
        def update(invoice_id, attributes) = billing.invoices.update(project_id, invoice_id, attributes)
        def delete(invoice_id) = billing.invoices.delete(project_id, invoice_id)
        def finalize(invoice_id, tz_offset: nil) = billing.invoices.finalize(project_id, invoice_id, tz_offset:)

        private

        def billing = @client.billing
      end
    end
  end
end
