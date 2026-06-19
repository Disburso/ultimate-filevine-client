# frozen_string_literal: true

module UltimateFilevineClient
  module Pagination
    DEFAULT_LIMIT = 50

    # Lazily iterates a paginated Filevine list endpoint (offset/limit), yielding
    # each item wrapped by the given block. Pages are fetched only as consumed, so
    # `.first` / `.take(n)` / `.lazy` issue the minimum number of requests.
    #
    # Each #each call runs an independent local cursor, so a Paginator is safe to
    # reuse and to iterate from multiple threads concurrently.
    class Paginator
      include Enumerable

      def initialize(connection:, path:, params: {}, limit: DEFAULT_LIMIT, &wrap)
        @connection = connection
        @path = path
        @params = params
        @limit = limit
        @wrap = wrap || ->(item) { item }
      end

      def each
        return enum_for(:each) unless block_given?

        offset = @params.fetch(:offset, 0)
        loop do
          body = @connection.get(@path, params: page_params(offset)).body
          items = Array(body["Items"])
          items.each { |item| yield @wrap.call(item) }
          break if items.empty? || !body["HasMore"]

          offset += items.size
        end
      end

      private

      def page_params(offset)
        @params.merge(offset:, limit: @limit)
      end
    end
  end
end
