# frozen_string_literal: true

module Rain
  class Route
    include LowType

    attr_reader :route, :verbs

    def initialize(route: String, verbs: Array[String | nil] | [])
      @route = route
      @verbs = verbs
    end
  end
end
