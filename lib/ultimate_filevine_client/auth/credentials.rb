# frozen_string_literal: true

module UltimateFilevineClient
  module Auth
    # Immutable per-tenant credentials for the Filevine gateway (PAT) flow.
    # Secrets are redacted from inspect/to_s so they do not leak into logs.
    Credentials = Data.define(:client_id, :client_secret, :pat) do
      def initialize(client_id:, client_secret:, pat:)
        validate!("client_id", client_id)
        validate!("client_secret", client_secret)
        validate!("pat", pat)
        super
      end

      def inspect
        "#<#{self.class.name} client_id=#{client_id.inspect} client_secret=[FILTERED] pat=[FILTERED]>"
      end
      alias_method :to_s, :inspect

      private

      def validate!(name, value)
        return unless value.nil? || value.to_s.strip.empty?

        raise ConfigurationError, "#{name} is required"
      end
    end
  end
end
