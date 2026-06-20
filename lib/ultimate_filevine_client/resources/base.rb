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

      # PATCH, wrapping the response in `entity`. `attributes` may be nil for
      # body-less updates (e.g. assigning a task via the URL only).
      def update_entity(path, entity, attributes = nil, params: nil)
        entity.new(connection.patch(path, **request_kwargs(attributes, params)).body)
      end

      # DELETE that returns a record rather than no content (some Filevine
      # "deletes" return the updated resource, e.g. unassigning a task returns
      # the now-unassigned task), wrapped in `entity`.
      def delete_entity(path, entity)
        entity.new(connection.delete(path).body)
      end

      # Perform a write whose response body is not needed; returns true (a
      # non-2xx response raises). For 204 / no-content action endpoints.
      def perform_action(http_method, path, body: nil, params: nil)
        connection.public_send(http_method, path, **request_kwargs(body, params))
        true
      end

      # DELETE returning true; a non-2xx response raises a RequestError.
      def delete_path(path) = perform_action(:delete, path)

      # A bulk write whose success is a 204 (no content) and whose partial
      # failure is a 207 multi-status body. Returns nil on full success or the
      # parsed multi-status hash (with per-item Results) on partial failure; a
      # non-2xx response still raises.
      def bulk_request(http_method, path, body:)
        result = connection.public_send(http_method, path, body: body).body
        result unless result.nil? || result == ""
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
