# frozen_string_literal: true

require_relative 'route'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    PARAM_DELIMITERS = ['/', ':', '-'].freeze

    attr_reader :root_node

    def initialize
      @root_node = TrieNode.new
    end

    def root_path_node
      @root_node.nodes['/']
    end

    def insert(route:)
      path = route.path

      current_node = @root_node
      current_index = 0

      while current_index < path.length
        key = path[current_index]

        if key == ':'
          key, current_index = capture_param(current_index:, path:)
        else
          current_index += 1
        end

        current_node = current_node.sub_node(key:)
      end

      current_node.route = route
    end

    def capture_param(current_index:, path:)
      current_index += 1
      chars = [':']

      path[current_index...path.length].chars.each do |char|
        break if PARAM_DELIMITERS.include?(char)
        current_index += 1
        chars << char
      end

      [chars.join, current_index]
    end
  end
end
