# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    module Billing
      # Timekeeper classifications (Billing) — reference data used by rate
      # schedules. Reached via client.billing.timekeeper_classifications.
      class TimekeeperClassifications < Base
        # All timekeeper classifications for the org (raw array of
        # { ID, Name, Description }).
        def list = connection.get("/fv-app/v2/classifications").body
      end
    end
  end
end
