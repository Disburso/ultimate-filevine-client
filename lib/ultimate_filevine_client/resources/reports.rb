# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Saved reports (/fv-app/v2/Reports). #list returns {Entities::Report}
    # records; #run executes one and returns the raw, untyped result set.
    class Reports < Base
      PATH = "/fv-app/v2/Reports"

      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(PATH, Entities::Report, limit:, **params)
      end

      # Run a saved report. Accepts limit/offset/tzOffset/includeTotalInJson
      # params; returns the executed report output as raw parsed JSON.
      def run(report_id, **params)
        connection.get("#{PATH}/#{report_id}", params: params).body
      end
    end
  end
end
