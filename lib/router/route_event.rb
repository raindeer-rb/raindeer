# frozen_string_literal: true

require 'low_event'

module Rain
  class RouteEvent < ::LowEvent
    attr_reader :route, :params

    def initialize(action: :handle, route:, params: Hash | nil)
      super(action:)

      @route = route
      @params = params
    end
  end
end
