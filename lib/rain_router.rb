require 'observers'

module Rain
  class Router
    extend Observers
    include LowType

    observe LowLoop

    class << self
      def handle(event: RequestEvent)
      end
    end

    class DSL
      extend Observers
      include LowType

      class << self
        def route(route = String)
          observable route
        end
      end
    end
  end
end
