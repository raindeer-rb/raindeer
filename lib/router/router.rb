# frozen_string_literal: true

require 'low_event'
require 'low_loop'
require 'observers'

require_relative 'route'
require_relative 'route_event'

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

    def route(route, verbs = [], &block)
      @breadcrumbs << route

      route = @breadcrumbs.join
      observable route
      @routes[route] = Route.new(path:, verbs: [*verbs])

      block.call if block_given?

      @breadcrumbs.pop
    end

    def get(route = String, &block)
      route(route, 'GET', &block)
    end

    def post(route = String, &block)
      route(route, 'POST', &block)
    end

    def update(route = String, &block)
      route(route, 'UPDATE', &block)
    end

    def delete(route = String, &block)
      route(route, 'DELETE', &block)
    end

    class << self
      # TODO: Add type: ::Low::RequestEvent
      def handle(event:)
        route = Trie.parse(event.request.path)
        route_event = RouteEvent.new(route:)
        trigger route_event
      end
    end
  end
end

RainRouter = Rain::Router
