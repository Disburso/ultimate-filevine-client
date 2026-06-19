# frozen_string_literal: true

module UltimateFilevineClient
  module TokenStore
    # Interface contract for per-tenant token caches.
    #
    # Implementations MUST be thread-safe. Keys are opaque strings produced by
    # {Configuration#token_key}; values are {Auth::Token} instances. Expiry is
    # the caller's concern, except where a backend (e.g. Redis TTL) enforces it.
    class Base
      def read(_key)
        raise NotImplementedError, "#{self.class}#read"
      end

      def write(_key, _token)
        raise NotImplementedError, "#{self.class}#write"
      end

      def delete(_key)
        raise NotImplementedError, "#{self.class}#delete"
      end
    end
  end
end
