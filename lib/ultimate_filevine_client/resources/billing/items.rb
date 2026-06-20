# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Billing items — time / expense / flat-fee lines (Billing). Reached via
      # client.billing.items. Paths are verbatim from the spec: list under
      # /billingitem, get under /billing, create/update under capitalized
      # /projects/{id}/BillingItem, and delete under /Billing/Delete.
      class Items < Base
        # Auto-paging list of {Entities::BillingItem}. With `project_id:` it lists
        # that project's items; without, the whole org. Filters (billingType:,
        # unsynced:, dateCreated:, startDate:, endDate:) pass straight through.
        def list(project_id: nil, limit: Pagination::DEFAULT_LIMIT, **params)
          path = project_id ? "/fv-app/v2/billingitem/projects/#{project_id}" : "/fv-app/v2/billingitem/org"
          list_entities(path, Entities::BillingItem, limit:, **params)
        end

        def get(project_id, billing_item_id)
          fetch_entity("/fv-app/v2/billing/projects/#{project_id}/billing-items/#{billing_item_id}",
                       Entities::BillingItem)
        end

        def create(project_id, attributes)
          create_entity("/fv-app/v2/projects/#{project_id}/BillingItem", Entities::BillingItem, attributes)
        end

        def update(project_id, billing_item_id, attributes)
          put_entity("/fv-app/v2/projects/#{project_id}/BillingItem/#{billing_item_id}",
                     Entities::BillingItem, attributes)
        end

        # Delete a billing item. Returns true on success.
        def delete(billing_item_id)
          delete_path("/fv-app/v2/Billing/Delete/BillingItem/#{billing_item_id}")
        end

        # Assign a note to a billing item. Returns true on success.
        def set_note(billing_item_id, project_id:, note_id:)
          perform_action(:put, "/fv-app/v2/billingitem/#{billing_item_id}/note",
                         body: { ProjectID: project_id, NoteID: note_id })
        end

        # Remove the note from a billing item. Returns true on success.
        def remove_note(project_id, billing_item_id)
          delete_path("/fv-app/v2/billingitem/#{project_id}/note/#{billing_item_id}")
        end

        # Attach documents to a billing item. `doc_ids` is an array of integer doc
        # ids. Returns true on success.
        def add_attachments(billing_item_id, project_id:, doc_ids:)
          perform_action(:post, "/fv-app/v2/billingitems/#{billing_item_id}/attachments",
                         body: { ProjectID: project_id, DocIDs: Array(doc_ids) })
        end

        # Remove document attachments from a billing item. Returns true on success.
        def remove_attachments(billing_item_id, project_id:, doc_ids:)
          perform_action(:delete, "/fv-app/v2/billingitems/#{billing_item_id}/attachments",
                         body: { ProjectID: project_id, DocIDs: Array(doc_ids) })
        end

        # Sync billing items to an accounting integration. `entries` is an array of
        # { BillingItemId:, SyncSuccessful:, Note:, SystemId: } records. Returns the
        # raw HTTP status the server reports.
        def accounting_sync(entries)
          connection.put("/fv-app/v2/AccountingSync", body: Array(entries)).body
        end
      end
    end
  end
end
