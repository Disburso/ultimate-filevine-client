# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Project trust funds (Billing). Reached via client.billing.funds. All paths
      # are under capitalized /Billing (verbatim from the spec).
      class Funds < Base
        # The project's current fund balance ({ "ProjectID", "ProjectName",
        # "FundBalance" }, raw).
        def balance(project_id)
          connection.get("/fv-app/v2/Billing/projects/#{project_id}/funds").body
        end

        # Create a fund transaction (deposit / retainer / debit / refund). Returns
        # the raw result, which carries both the new transaction and the resulting
        # FundBalance.
        def create(project_id, attributes)
          connection.post("/fv-app/v2/Billing/projects/#{project_id}/funds", body: attributes).body
        end

        def get(project_id, fund_id)
          fetch_entity("/fv-app/v2/Billing/projects/#{project_id}/funds/#{fund_id}", Entities::ProjectFund)
        end

        # Void a fund transaction. Returns the raw result (transaction + balance).
        def void(project_id, fund_id)
          connection.put("/fv-app/v2/Billing/projects/#{project_id}/funds/#{fund_id}/void").body
        end

        # The project's fund transactions as an array of {Entities::ProjectFund}.
        # This endpoint returns a bare { Count, ProjectFunds } list (not the
        # standard Items envelope), so it is not auto-paging — pass limit:/offset:/
        # startDate:/endDate: as filters to page manually.
        def list(project_id, **params)
          body = connection.get("/fv-app/v2/Billing/projects/#{project_id}/fundslist", params: params).body
          Array(body["ProjectFunds"]).map { |item| Entities::ProjectFund.new(item) }
        end
      end
    end
  end
end
