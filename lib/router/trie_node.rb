# frozen_string_literal: true

module Rain
  class TrieNode
    include LowType

    attr_reader :nodes
    attr_accessor :route

    def initialize
      @nodes = {}
      @route = nil
    end

    def insert(route:)
      current_node = self

      route.path.chars.each do |char|
        current_node = current_node.nodes[char] || current_node.nodes[char] = TrieNode.new
      end

      current_node.route = route
    end
  end
end
