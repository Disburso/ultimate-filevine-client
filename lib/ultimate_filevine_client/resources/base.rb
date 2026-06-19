# frozen_string_literal: true

module UltimateFilevineClient
  module Resources
    # Base for resource collections (e.g. Projects). Holds the owning {Client}
    # and provides request + pagination helpers. Resources are stateless beyond
    # the client reference, so they are safe to share across threads.
    class Base
      def initialize(client)
        @client = client
      end

      private

      def connection
        @client.connection
      end

      def paginate(path, params: {}, limit: Pagination::DEFAULT_LIMIT, &wrap)
        Pagination::Paginator.new(connection: connection, path: path, params: params, limit: limit, &wrap)
      end
    end
  end
end
