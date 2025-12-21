# frozen_string_literal: true

require 'low_event'
require 'low_loop'
require 'observers'
require_relative 'events/route_event'

module Rain
  class Router
    include LowType

    extend Observers
    observe LowLoop

    class << self
      # TODO: Add type: ::Low::RequestEvent
      def handle(event: nil)
        route = PrefixTree.parse(event.request.path)
        route_event = RouteEvent.new(route:)
        trigger route_event
      end
    end

    def get(route = String)
      observable route
    end

    def post(route = String)
      observable route
    end

    def update(route = String)
      observable route
    end

    def delete(route = String)
      observable route
    end
  end
end

RainRouter = Rain::Router
