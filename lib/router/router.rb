# frozen_string_literal: true

require 'low_event'
require 'providers'

require_relative 'events/route_event'
require_relative 'events/wildcard_event'
require_relative 'route'
require_relative 'trie'

module Rain
  class Router
    include LowType
    include Observers

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

    def handle(event: Low::Events::RequestEvent)
      response_event = nil

      # The last route event will render a response event which we want to return to the request event.
      @trie.match(path: event.request.path).each do |route_event|
        response_event = route_event.trigger
      end
      return response_event if response_event

      if @routes['/*']
        route = Route.new(path: event.request.path, verbs: @routes['/*'].verbs)
        wildcard_event = WildcardEvent.trigger(key: '/*', action: :render, route:)
        return wildcard_event if wildcard_event
      end

      Low::Events::StatusEvent.trigger(status: Low::Types::Status[404], request: event.request)
    end
  end
end
