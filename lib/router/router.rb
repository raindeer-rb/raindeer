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

    attr_reader :routes, :trie

    def initialize
      @routes = {}
      @breadcrumbs = []
      @trie = Trie.new
    end

    def route(path, verbs = [], &block)
      @breadcrumbs << path

      path = @breadcrumbs.join
      observable path
      @routes[path] = Route.new(path:, verbs: [*verbs])

      block.call if block_given?

      @breadcrumbs.pop
    end

    def get(path = String, &block)
      route(path, 'GET', &block)
    end

    def post(path = String, &block)
      route(path, 'POST', &block)
    end

    def update(path = String, &block)
      route(path, 'UPDATE', &block)
    end

    def delete(path = String, &block)
      route(path, 'DELETE', &block)
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
