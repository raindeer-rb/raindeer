# frozen_string_literal: true

require_relative '../router/http'
require_relative '../router/events/route_event'
require_relative '../router/events/wildcard_event'

class LowNode
  include Rain::HTTP
  include Rain::Events
end
