# frozen_string_literal: true

module UltimateFilevineClient
  module Entities
    # Read-only wrapper over a raw Filevine resource hash (string-keyed JSON).
    # Subclasses add convenience accessors; the raw payload stays available via
    # {#[]} and {#to_h} so nothing is lost.
    class Base
      def initialize(attributes)
        @attributes = attributes || {}
      end

      # Raw field access by its Filevine (PascalCase) key.
      def [](key)
        @attributes[key.to_s]
      end

      def to_h
        @attributes
      end

      def ==(other)
        other.is_a?(self.class) && other.to_h == to_h
      end
      alias eql? ==

      def hash
        [self.class, @attributes].hash
      end

      private

      # Extract the numeric `Native` id from an Identifier-typed field
      # ({ "Native" => Integer, "Partner" => String }).
      def native_id(key)
        value = self[key]
        value.is_a?(Hash) ? value["Native"] : value
      end
    end
  end
end
