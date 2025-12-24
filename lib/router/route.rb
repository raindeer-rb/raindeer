# frozen_string_literal: true

module Rain
  class Route
    include LowType

    attr_reader :path, :verbs

    def initialize(path: String, verbs: Array[String | nil] | [])
      @path = path
      @verbs = verbs
    end
  end
end
