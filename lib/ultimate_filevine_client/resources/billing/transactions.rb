# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Billing transactions — payments and refunds (Billing). Reached via
      # client.billing.transactions. Reads live under capitalized /Billing while
      # the writes live under lowercase /billing (verbatim from the spec).
      class Transactions < Base
        # Auto-paging list of {Entities::Transaction} for a project. Filters
        # (justUnapplied:, transactionType:, startDate:, endDate:) pass through.
        def list(project_id, limit: Pagination::DEFAULT_LIMIT, **params)
          list_entities("/fv-app/v2/Billing/projects/#{project_id}/transactions",
                        Entities::Transaction, limit:, **params)
        end

        def get(transaction_id)
          fetch_entity("/fv-app/v2/Billing/transactions/#{transaction_id}", Entities::Transaction)
        end

        # Create a payment on a project. Returns the created {Entities::Transaction}.
        def create_payment(project_id, attributes)
          create_entity("/fv-app/v2/billing/projects/#{project_id}/payment", Entities::Transaction, attributes)
        end

        # Create a payment and apply it to invoices in one call.
        def create_and_apply_payment(project_id, attributes)
          create_entity("/fv-app/v2/billing/projects/#{project_id}/payment/apply",
                        Entities::Transaction, attributes)
        end

        def update_payment(project_id, transaction_id, attributes)
          put_entity("/fv-app/v2/billing/projects/#{project_id}/payment/#{transaction_id}",
                     Entities::Transaction, attributes)
        end

        # Create a refund on a project. Returns the created {Entities::Transaction}.
        def create_refund(project_id, attributes)
          create_entity("/fv-app/v2/billing/projects/#{project_id}/refund", Entities::Transaction, attributes)
        end

        def update_refund(project_id, transaction_id, attributes)
          put_entity("/fv-app/v2/billing/projects/#{project_id}/refund/#{transaction_id}",
                     Entities::Transaction, attributes)
        end

        # Void a transaction. The spec's DELETE returns the now-voided transaction
        # rather than no content, so this returns an {Entities::Transaction}.
        def void(project_id, transaction_id)
          delete_entity("/fv-app/v2/billing/projects/#{project_id}/transactions/#{transaction_id}",
                        Entities::Transaction)
        end

        # Unapply a payment from an invoice. Returns true on success.
        def unapply_payment(project_id, invoice_id: nil, transaction_id: nil)
          body = { InvoiceID: invoice_id, TransactionID: transaction_id }.compact
          perform_action(:delete, "/fv-app/v2/billing/projects/#{project_id}/unapply-payment", body: body)
        end

        # Apply an existing payment transaction to an invoice for `amount`. Returns
        # the raw application result (balances after applying).
        def apply_payment(invoice_id:, transaction_id:, amount:)
          connection.put(
            "/fv-app/v2/Billing/invoices/#{invoice_id}/transactions/#{transaction_id}/#{amount}"
          ).body
        end
      end
    end
  end
end
