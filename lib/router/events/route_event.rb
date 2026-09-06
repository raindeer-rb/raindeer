# frozen_string_literal: true

require 'low_event'

module Rain
  class RouteEvent < ::LowEvent
    attr_reader :route, :params

    def initialize(route:, action: :render, params: Hash | nil)
      super(key: route.path, action:)

      @route = route
      @params = params
    end
  end
end
