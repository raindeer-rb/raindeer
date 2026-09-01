# frozen_string_literal: true

module System
  class EventsNode < LowNode
    observe '/system/events'

    def initialize(event:)
      # TODO: Include types that can be observed keys too like Status and Status[404].
      @event_types = LowEvent.events
      @event_trees = Providers['low.event.pool'].event_trees.values.reverse
    end

    def render(event:)
      <{ LayoutNode: }>
        <h1>{"Events"}</h1>

        <table>
          <thead>
            <tr>
              <th scope="col">Event</th>
              <th scope="col">Observers</th>
            </tr>
          </thead>
          <tbody>
            <{ for: observer_key in: @event_types }>
              <tr>
                <td>{observer_key}</td>
                <td>
                  <{ ObserversFormatter observer_key=observer_key }>
                </td>
              </tr>
            <{ :for }>
          </tbody>
        </table>

        <h2>{"Recent Requests"}</h2>

        <{ for: event_tree in: @event_trees }>
          <{ EventTraceFormatter event_tree=event_tree }>
        <{ :for }>
      <{ :LayoutNode }>
    end
  end
end
