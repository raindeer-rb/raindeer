# frozen_string_literal: true

require 'antlers/api'

module Rain
  class ListNode < Antlers::BranchNode
    include Antlers::Props
    include Antlers::Variables

    DEF_KEY = :list_def
    END_KEY = :list_end

    def initialize(value:, folder:, props: [], children: [])
      super(name: :toc, props:, children:)

      @value = value.delete("'").delete('"')
      @folder = folder.delete("'").delete('"')
    end

    def render(current_binding: nil, parent_binding: nil, slot_node: nil, metadata: {})
      output = ''

      list = metadata.list(folder: @folder)

      list.each do |value|
        # TODO: Parallelize by creating new bindings and ensuring children have any args they need via RenderEvent.
        current_binding.local_variable_set(@value, value)

        @children.each do |child|
          output += child.render(current_binding:, parent_binding:, slot_node:, metadata:) || ''
        end
      end

      output
    end

    class << self
      def match?(segment:)
        segment[DEF_KEY]
      end

      def build(segment:, **)
        new(value: segment[:list_def], folder: segment[:folder])
      end
    end
  end
end
