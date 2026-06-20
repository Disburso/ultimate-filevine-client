# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Org deadline chain types (/fv-app/v2/chaintypes). Note the lowercase path —
    # Filevine paths are case-sensitive and this one is not capitalized.
    class DeadlineChainTypes < Base
      PATH = "/fv-app/v2/chaintypes"

      # Auto-paging list of {Entities::ChainType}. Pass `name:` to filter by name.
      def list(limit: Pagination::DEFAULT_LIMIT, **params)
        list_entities(PATH, Entities::ChainType, limit:, **params)
      end
    end
  end
end
