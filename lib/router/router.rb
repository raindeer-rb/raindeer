# frozen_string_literal: true

require 'low_event'
require 'providers'

require_relative 'route'
require_relative 'route_event'
require_relative 'trie'
require_relative 'wildcard_event'

module Rain
  class Router
    include LowType
    include Observers

    attr_reader :routes, :trie

    def initialize
      @breadcrumbs = []
      @routes = {}
      @trie = Trie.new
    end

    def route(path, verbs = [], &block)
      @breadcrumbs << path
      path = @breadcrumbs.join

      route = Route.new(path:, verbs: [*verbs])
      @routes[path] = route
      @trie.merge(route:)

      block.call if block_given?

      @breadcrumbs.pop
    end

    def get(path, &block)
      route(path, 'GET', &block)
    end

    def post(path, &block)
      route(path, 'POST', &block)
    end

    def update(path, &block)
      route(path, 'UPDATE', &block)
    end

    def delete(path, &block)
      route(path, 'DELETE', &block)
    end

    # TODO: Define type: ::Low::Events::RequestEvent
    # You can override any route/status simply by adding your own observer.
    def handle(event:)
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
