# frozen_string_literal: true

class ObserversFormatter < LowNode
  def initialize(event:, observer_key:)
    # TODO: What's the best way to do this? An "if:" at the template layer? A decorator at the node layer?
    if observer_key.to_s == 'Rain::Events::RouteEvent'
      routes_count = Providers['rain.router'].routes.count
      @observers = ["#{routes_count} routes"]
    else
      @observers = Observers[observer_key].map { it.object }
    end
  end
    
  def render(event:, observer_key:)
    <ul>
      <{ for: observer in: @observers }>
        <li>{ observer }</li>
      <{ :for }>
    </ul>
  end
end
