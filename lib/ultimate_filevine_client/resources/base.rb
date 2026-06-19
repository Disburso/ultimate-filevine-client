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

      # An auto-paging collection of `entity`-wrapped records.
      def list_entities(path, entity, limit: Pagination::DEFAULT_LIMIT, **params)
        paginate(path, params: params, limit: limit) { |item| entity.new(item) }
      end

      def fetch_entity(path, entity)
        entity.new(connection.get(path).body)
      end

      def create_entity(path, entity, attributes)
        entity.new(connection.post(path, body: attributes).body)
      end

      def update_entity(path, entity, attributes)
        entity.new(connection.patch(path, body: attributes).body)
      end
    end
  end
end
