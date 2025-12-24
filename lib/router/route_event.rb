# frozen_string_literal: true

require 'low_event'

module Rain
  class RouteEvent < ::LowEvent
    attr_reader :route, :params

    def initialize(route: String, params: Hash | nil)
      super()

      @route = route
      @params = params
    end
  end
end
