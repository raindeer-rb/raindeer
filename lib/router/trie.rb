# frozen_string_literal: true

require_relative 'route'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    attr_reader :root_node

    def initialize
      @root_node = TrieNode.new
      insert(route: Route.new(path: '/'))
    end

    def nodes
      @root_node.nodes
    end

    def insert(route:)
      current_node = @root_node

      route.path.chars.each do |key|
        current_node = current_node.sub_node(key:)
      end

      current_node.route = route
    end
  end
end
