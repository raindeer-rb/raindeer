require 'low_event'
require 'observers'
require_relative 'events/route_event'

module Rain
  class Router
    include LowType

    extend Observers
    observe LowLoop

    class << self
      def handle(event: ::Low::RequestEvent)
        route = PrefixTree.parse(event.request.path)
        route_event = RouteEvent.new(route:)
        trigger route_event
      end
    end

    class DSL
      extend Observers

      class << self
        def get(route)
          observable route
        end

        def post(route)
          observable route
        end

        def update(route)
          observable route
        end

        def delete(route)
          observable route
        end
      end
    end
  end
end

RainRouter = Rain::Router
