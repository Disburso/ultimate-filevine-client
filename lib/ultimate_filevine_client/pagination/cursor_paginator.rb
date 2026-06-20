# frozen_string_literal: true

module UltimateFilevineClient
  module Pagination
    # Lazily iterates a keyset/cursor-paginated endpoint whose response nests its
    # records under a custom key and advances via an opaque cursor rather than
    # offset/limit (e.g. Share Links: records under "ShareLinks", cursor carried
    # from the response's "NewLastKey" into the next request's "lastKey").
    #
    # Like {Paginator}, each #each runs an independent cursor and fetches pages
    # only as consumed, so it is lazy and safe to iterate from multiple threads.
    class CursorPaginator
      include Enumerable

      def initialize(connection:, path:, items_key:, cursor_param:, next_cursor_key:,
                     params: {}, limit: DEFAULT_LIMIT, &wrap)
        @connection = connection
        @path = path
        @items_key = items_key
        @cursor_param = cursor_param
        @next_cursor_key = next_cursor_key
        @params = params
        @limit = limit
        @wrap = wrap || ->(item) { item }
      end

      def each
        return enum_for(:each) unless block_given?

        cursor = @params[@cursor_param]
        loop do
          body = @connection.get(@path, params: page_params(cursor)).body
          items = Array(body[@items_key])
          items.each { |item| yield @wrap.call(item) }
          cursor = body[@next_cursor_key]
          break if last_page?(items, body, cursor)
        end
      end

      private

      def last_page?(items, body, cursor)
        items.empty? || !body["HasMore"] || cursor.nil? || cursor.to_s.empty?
      end

      def page_params(cursor)
        params = @params.merge(limit: @limit)
        params[@cursor_param] = cursor unless cursor.nil?
        params
      end
    end
  end
end
