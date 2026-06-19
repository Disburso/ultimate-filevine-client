# frozen_string_literal: true

module UltimateFilevineClient
  # Resolves a region/cell key to its gateway + identity host pair.
  #
  # Only the US cell is confirmed. Canada and CJIS hosts are intentionally
  # omitted until verified against the live docs rather than guessed.
  module Region
    Hosts = Data.define(:api, :identity)

    HOSTS = {
      us: Hosts.new(api: "https://api.filevineapp.com", identity: "https://identity.filevine.com")
    }.freeze

    SUPPORTED = HOSTS.keys.freeze

    module_function

    # @param region [Symbol, String]
    # @return [Region::Hosts]
    # @raise [ConfigurationError] for unknown/unconfirmed regions
    def resolve(region)
      HOSTS.fetch(region.to_sym) do
        raise ConfigurationError,
              "Unsupported region #{region.inspect}. Supported: " \
              "#{SUPPORTED.map(&:inspect).join(", ")} (CA/CJIS hosts are not yet confirmed)."
      end
    end
  end
end
