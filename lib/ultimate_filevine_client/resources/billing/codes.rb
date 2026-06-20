# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Billing code sets (Billing). Reached via client.billing.codes. These are
      # reference data (sets of time/expense codes), returned as raw hashes.
      class Codes < Base
        # The org's available billing code sets (raw array).
        def org = connection.get("/fv-app/v2/Billing/AvailableBillingCodes").body

        # A project's available billing code sets (raw array).
        def project(project_id)
          connection.get("/fv-app/v2/Billing/#{project_id}/AvailableBillingCodes").body
        end

        # Add codes to a code set. `codes` is an array of { Key:, Description: }.
        # Returns true on success.
        def add_to_set(billing_code_set_id, codes)
          perform_action(:post, "/fv-app/v2/Billing/BillingCodeSet/#{billing_code_set_id}/BillingCodes",
                         body: Array(codes))
        end
      end
    end
  end
end
