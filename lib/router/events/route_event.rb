# frozen_string_literal: true

require 'low_event'

module Rain
  class RouteEvent < ::LowEvent
    attr_reader :route, :params

    def initialize(route:, action: :render, params: Hash | nil)
      if action == :render
        super(key: route.path, actions: [:render, :get, :delete])
      elsif action == :receive
        super(key: route.path, actions: [:receive, :query, :post, :put, :patch])
      else
        super(key: route.path, action:)
      end

      @route = route
      @params = params
    end
  end
end
