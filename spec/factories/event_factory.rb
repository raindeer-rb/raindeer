# frozen_string_literal: true

require 'lowevent'
require_relative '../fixtures/mock_events'

module Fixtures
  class EventFactory
    class << self
      def request_response_tree(request_id:, created_at: nil)
        event_tree = Low::Events::EventTree.new(request_id:)
        event_tree.branch(event: RequestEvent.new(created_at:))
        event_tree.branch(event: ResponseEvent.new(created_at:))
        event_tree
      end

      # TODO: Replace above method (and test expectations) with this more realistic order of events.
      def request_route_tree(request_id:, created_at: nil)
        event_tree = Low::Events::EventTree.new(request_id:)
        event_tree.branch(event: RequestEvent.new(created_at:))
        event_tree.branch(event: RouteEvent.new(created_at:))
        event_tree
      end

      def route_event(created_at: nil)
        RouteEvent.new(created_at:)
      end
    end
  end
end
