# frozen_string_literal: true

require 'low_event'

require_relative 'events/route_event'
require_relative 'events/wildcard_event'
require_relative 'http'
require_relative 'route'
require_relative 'trie'

module Rain
  # Defines routes and routes requests to a matching route event.
  class Router
    include LowType
    include Observers
    include Low::Events
    include Low::Types
    include Rain::HTTP

    attr_reader :routes, :trie

    def initialize
      @current_level = []
      @routes = {}
      @trie = Trie.new
    end

    def route(value, &block)
      path, verbs = Route.decode(value:)

      @current_level << path
      path = @current_level.join

      route = Route.new(path:, verbs:)
      @routes[path] = route
      @trie.merge(route:)

      block.call if block_given?

      @current_level.pop
    end

    def get(path, &block)
      route(GET => path, &block)
    end

    def post(path, &block)
      route(POST => path, &block)
    end

    def update(path, &block)
      route(UPDATE => path, &block)
    end

    def delete(path, &block)
      route(DELETE => path, &block)
    end

    def request(event: RequestEvent)
      response_event = nil

      # The last route event will render a response event which we want to return to the request event.
      @trie.match(request: event.request).each do |route_event|
        response_event = route_event.take
      end
      return response_event if response_event

      if @routes['/*']
        route = Route.new(path: event.request.path, verbs: @routes['/*'].verbs)
        wildcard_event = WildcardEvent.take(key: '/*', action: :render, route:)
        return wildcard_event if wildcard_event
      end

      StatusEvent.take(status: Status[404], request: event.request)
    end
  end
end
