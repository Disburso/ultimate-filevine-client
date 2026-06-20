# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Billing settings and vitals (Billing). Reached via client.billing.settings.
      # All responses are configuration/value blobs, returned raw. Note the
      # verbatim casing quirk: reads use /billingsettings (one word) while the
      # update uses /billing-settings (hyphenated).
      class Settings < Base
        # Org-level billing settings (raw).
        def org = connection.get("/fv-app/v2/Billing/org/Settings").body

        # A project's billing settings (raw).
        def get(project_id)
          connection.get("/fv-app/v2/Billing/projects/#{project_id}/billingsettings").body
        end

        # Update a project's billing settings. Returns the raw { Success, Message }.
        def update(project_id, attributes)
          connection.put("/fv-app/v2/Billing/projects/#{project_id}/billing-settings", body: attributes).body
        end

        # A project's billing vitals ({ "CurrentBalance", "InProgressBalance",
        # "ProjectFundsBalance" }, raw).
        def vitals(project_id)
          connection.get("/fv-app/v2/Billing/projects/#{project_id}/billingVitals").body
        end

        # The project's LEDES client/matter id (raw string).
        def client_matter_id(project_id)
          connection.get("/fv-app/v2/Billing/projectbillingsettings/#{project_id}/clientMatterId").body
        end

        # Set the project's LEDES client/matter id. Returns the raw boolean result.
        def set_client_matter_id(project_id, client_matter_id)
          connection.post("/fv-app/v2/Billing/projectbillingsettings/#{project_id}/clientMatterId",
                          params: { clientMatterId: client_matter_id }).body
        end

        # A project's fund settings (raw { InitialFunds, FundsThreshold, CanEdit }).
        def fund_settings(project_id)
          connection.get("/fv-app/v2/Billing/projects/#{project_id}/projectFundSettings").body
        end

        # Update a project's fund settings. Returns the raw updated settings.
        def update_fund_settings(project_id, attributes)
          connection.put("/fv-app/v2/Billing/projects/#{project_id}/projectFundSettings", body: attributes).body
        end
      end
    end
  end
end
