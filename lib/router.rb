# frozen_string_literal: true

require 'low_event'
require 'low_loop'
require 'observers'
require_relative 'events/route_event'

module Rain
  class Router
    include LowType
    include Observers

    observe LowLoop

    attr_reader :routes

    def initialize
      @routes = {}
      @breadcrumbs = []
    end

    def route(route, verb: 'GET')
      @breadcrumbs << route

      route = @breadcrumbs.join
      @routes[route] = route

      yield if block_given?

      @breadcrumbs.pop
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

    class << self
      # TODO: Add type: ::Low::RequestEvent
      def handle(event:)
        binding.pry
        route = Trie.parse(event.request.path)
        route_event = RouteEvent.new(route:)
        trigger route_event
      end
    end
  end
end

RainRouter = Rain::Router
