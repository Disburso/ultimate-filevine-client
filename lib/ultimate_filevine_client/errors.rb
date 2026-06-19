# frozen_string_literal: true

module UltimateFilevineClient
  # Raised when configuration or credentials are invalid, or a region is unknown.
  class ConfigurationError < Error; end

  # Raised when a bearer token cannot be minted from the Filevine identity service.
  class AuthenticationError < Error; end
end
