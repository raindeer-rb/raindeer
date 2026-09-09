# frozen_string_literal: true

require_relative 'http'

module Rain
  class Route
    include LowType

    attr_reader :path, :verbs

    def initialize(path: String, verbs: Array[Symbol] | [])
      @path = path
      @verbs = verbs
    end

    class << self
      # Route[] is used as a value object to access existing routes.
      # Create new routes with new() instead... collection syntax is misused too frequently for instantiation.
      def [](value)
        path, verbs = decode(value:)
        new(path:, verbs:)
      end

      def decode(value: String | Hash)
        if value.is_a?(Hash)
          return [value.values.first, [*value.keys.first]]
        end
        
        [value, HTTP::VERBS]
      end
    end
  end
end
