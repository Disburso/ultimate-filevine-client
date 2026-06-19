# frozen_string_literal: true

require "concurrent/map"

module UltimateFilevineClient
  module TokenStore
    # Default token store: process-local and thread-safe via Concurrent::Map.
    #
    # Tokens live only in this process's memory. For cross-process reuse (sharing
    # a tenant's token across workers/dynos), supply a Redis-backed store instead.
    class MemoryStore < Base
      def initialize
        super
        @map = Concurrent::Map.new
      end

      def read(key)
        @map[key]
      end

      def write(key, token)
        @map[key] = token
        token
      end

      def delete(key)
        @map.delete(key)
      end

      def clear
        @map.clear
      end
    end
  end
end
