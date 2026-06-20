# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Invoices (Billing). Reached via client.billing.invoices. The current
      # (non-deprecated) endpoints span three path roots — verbatim from the spec,
      # whose casing is inconsistent: list/get under /billingitem, create/update/
      # delete/finalize under lowercase /projects, and the status/lifecycle writes
      # under lowercase /billing.
      class Invoices < Base
        ORG_PATH = "/fv-app/v2/billingitem/invoices"

        # Auto-paging list of {Entities::Invoice}. With `project_id:` it lists that
        # project's invoices; without, the whole org. Filters (status:, startDate:,
        # endDate:) pass straight through.
        def list(project_id: nil, limit: Pagination::DEFAULT_LIMIT, **params)
          path = project_id ? "/fv-app/v2/billingitem/projects/#{project_id}/invoices" : ORG_PATH
          list_entities(path, Entities::Invoice, limit:, **params)
        end

        def get(invoice_id) = fetch_entity("/fv-app/v2/billingitem/invoices/#{invoice_id}", Entities::Invoice)

        # Create an invoice on a project. Returns the created {Entities::Invoice}
        # (the response carries the new InvoiceID).
        def create(project_id, attributes)
          create_entity("/fv-app/v2/projects/#{project_id}/invoices", Entities::Invoice, attributes)
        end

        def update(project_id, invoice_id, attributes)
          put_entity("/fv-app/v2/projects/#{project_id}/invoices/#{invoice_id}", Entities::Invoice, attributes)
        end

        # Delete an invoice. Returns true on success.
        def delete(project_id, invoice_id)
          delete_path("/fv-app/v2/projects/#{project_id}/invoices/#{invoice_id}")
        end

        # Finalize an invoice (locks it and renders its document). `tz_offset` is
        # the caller's timezone offset in minutes. Returns the raw finalize result.
        def finalize(project_id, invoice_id, tz_offset: nil)
          params = tz_offset.nil? ? nil : { tzOffset: tz_offset }
          connection.post("/fv-app/v2/projects/#{project_id}/invoices/#{invoice_id}/finalize",
                          **request_kwargs(nil, params)).body
        end

        # The invoice PDF document locator ({ "Url", "ContentType", "DocumentId" }).
        def pdf(invoice_id) = connection.get("/fv-app/v2/billing/invoices/#{invoice_id}/pdf").body

        def update_description(invoice_id:, project_id:, description:)
          body = { InvoiceID: invoice_id, ProjectID: project_id, Description: description }
          put_entity("/fv-app/v2/billing/invoices/description", Entities::Invoice, body)
        end

        def update_status(invoice_id:, project_id:, status:)
          body = { InvoiceID: invoice_id, ProjectID: project_id, Status: status }
          put_entity("/fv-app/v2/billing/invoices/status", Entities::Invoice, body)
        end

        # Void an invoice. Returns true on success.
        def void(invoice_id:, project_id:)
          perform_action(:put, "/fv-app/v2/billing/invoices/void",
                         body: { InvoiceID: invoice_id, ProjectID: project_id })
        end

        # Write off an invoice. Returns true on success.
        def write_off(invoice_id:, project_id:)
          perform_action(:put, "/fv-app/v2/billing/invoices/writeoff",
                         body: { InvoiceID: invoice_id, ProjectID: project_id })
        end

        # Approve an invoice. Returns true on success.
        def approve(invoice_id) = perform_action(:post, "/fv-app/v2/billing/invoices/#{invoice_id}/approve")

        # Mark an invoice as sent. `timezone_offset` is in minutes. Returns true.
        def mark_as_sent(invoice_id, timezone_offset: nil)
          params = timezone_offset.nil? ? nil : { timezoneOffset: timezone_offset }
          perform_action(:post, "/fv-app/v2/billing/invoices/#{invoice_id}/mark-as-sent", params: params)
        end

        # Send an invoice for approval. Returns true on success.
        def send_for_approval(invoice_id)
          perform_action(:post, "/fv-app/v2/billing/invoices/#{invoice_id}/send-for-approval")
        end
      end
    end
  end
end
