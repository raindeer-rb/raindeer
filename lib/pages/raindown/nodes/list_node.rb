# frozen_string_literal: true

require 'antlers/api'
require 'nokogiri'

module Rain
  class ListNode < Antlers::BranchNode
    include Antlers::Props
    include Antlers::Variables

    DEF_KEY = :list_def
    END_KEY = :list_end

    def initialize(name:, keywords:, value:, key: nil, props: [], children: [])
      super(name:, props:, children:)

      @keywords = keywords
      @value = value
      @key = key
    end

    def render(current_binding: nil, parent_binding: nil, slot_node: nil)
      output = ''

      evaluate(name: @items, current_binding:).each do |value|
        key, value = value if @key

        # TODO: Parallelize by creating new bindings and ensuring children have any args they need via RenderEvent.
        current_binding.local_variable_set(@value, value)
        current_binding.local_variable_set(@key, key) if @key

        @children.each do |child|
          output += child.render(current_binding:, parent_binding:, slot_node:) || ''
        end
      end

      output
    end

    class << self
      def match?(segment:)
        segment[DEF_KEY]
      end

      def build(segment:, **)
        value, key, *keywords = segment.values_at(DEF_KEY, :key)
        new(name: value, key:, value:, keywords:)
      end
    end
  end
end
