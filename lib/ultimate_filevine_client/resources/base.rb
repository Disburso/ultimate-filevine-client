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

      # Keyset/cursor pagination (custom items key + opaque cursor) for the few
      # endpoints that don't use the standard offset/limit + "Items" contract.
      def cursor_paginate(path, items_key:, cursor_param:, next_cursor_key:,
                          params: {}, limit: Pagination::DEFAULT_LIMIT, &wrap)
        Pagination::CursorPaginator.new(
          connection: connection, path: path, items_key: items_key, cursor_param: cursor_param,
          next_cursor_key: next_cursor_key, params: params, limit: limit, &wrap
        )
      end

      # An auto-paging collection of `entity`-wrapped records.
      def list_entities(path, entity, limit: Pagination::DEFAULT_LIMIT, **params)
        paginate(path, params: params, limit: limit) { |item| entity.new(item) }
      end

      def fetch_entity(path, entity)
        entity.new(connection.get(path).body)
      end

      # POST, wrapping the response in `entity`. `attributes` may be nil for
      # body-less action endpoints (e.g. pin/unpin); `params` adds query string.
      def post_entity(path, entity, attributes = nil, params: nil)
        entity.new(connection.post(path, **request_kwargs(attributes, params)).body)
      end
      alias create_entity post_entity

      def put_entity(path, entity, attributes)
        entity.new(connection.put(path, body: attributes).body)
      end

      def update_entity(path, entity, attributes)
        entity.new(connection.patch(path, body: attributes).body)
      end

      # DELETE returning true; a non-2xx response raises a RequestError.
      def delete_path(path)
        connection.delete(path)
        true
      end

      def request_kwargs(body, params)
        kwargs = {}
        kwargs[:body] = body unless body.nil?
        kwargs[:params] = params unless params.nil?
        kwargs
      end
    end
  end
end
