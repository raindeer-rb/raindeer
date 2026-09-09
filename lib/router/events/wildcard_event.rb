# frozen_string_literal: true

require 'low_event'

module Rain
  class WildcardEvent < ::LowEvent
    attr_reader :route, :params

    def initialize(key:, route:, action: :render)
      super(key:, action:)

      @route = route
    end
  end
end
