# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # FV Payments — hosted payment links and deposit-destination account
      # mappings (Billing). Reached via client.billing.fv_payments. All responses
      # are returned raw.
      class FvPayments < Base
        # A hosted payment link for a specific invoice ({ "Success", "Url", ... }).
        def invoice_payment_link(invoice_id)
          connection.get("/fv-app/v2/Billing/invoice/#{invoice_id}/paymentlink").body
        end

        # An open-ended hosted payment link for a project.
        def project_payment_link(project_id)
          connection.get("/fv-app/v2/billing/projects/#{project_id}/payment-link").body
        end

        # The org's mapped FV Payments deposit destinations (raw).
        def account_mappings = connection.get("/fv-app/v2/billing/account-mappings").body

        # The org's deposit destinations available to be mapped (raw array).
        def available_account_mappings = connection.get("/fv-app/v2/billing/account-mappings/list").body

        # A project's mapped FV Payments deposit destinations (raw).
        def project_account_mappings(project_id)
          connection.get("/fv-app/v2/billing/projects/#{project_id}/account-mappings").body
        end
      end
    end
  end
end
