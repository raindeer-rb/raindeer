require 'low_event'

module Rain
  class RouteEvent < ::LowEvent
    def initialize(route: String, params: Hash | nil)
      super()

      @route = route
      @params = params
    end
  end
end
