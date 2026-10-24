# frozen_string_literal: true

require 'lowevent'

module Rain
  module Events
    class WildcardEvent < ::LowEvent
      attr_reader :route, :params

      def initialize(key:, route:, action: :render)
        super(key:, action:)

        @route = route
      end
    end
  end
end
