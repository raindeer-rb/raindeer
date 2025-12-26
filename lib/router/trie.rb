# frozen_string_literal: true

require_relative 'route'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    PARAM_DELIMITERS = ['/', ':'].freeze

    attr_reader :root_node

    def initialize
      @root_node = TrieNode.new
    end

    def root_path_node
      @root_node.nodes['/']
    end

    def insert(route:, current_node: @root_node, current_index: 0)
      path = route.path

      while current_index < path.length
        key = path[current_index]

        if key == ':'
          key, current_index = capture_param(current_index:, path:)
        else
          current_index += 1
        end

        current_node = current_node.upsert_child(key:)
      end

      current_node.route = route
    end

    def match(path:, current_node: @root_node, current_index: 0)
      matches = []

      # Static match.
      key = path[current_index]
      return [] if key.nil?
      if (child_node = current_node.child(key:))
        matches << child_node.route if child_node.route
        return [*matches, *match(path:, current_node: child_node, current_index: current_index += 1)]
      end

      # # Dynamic match.
      # current_node.params.each do |param|
      #   _param_key, param_end_index = capture_param(current_index:, path:)
      #   matches = [*matches, *match(path:, current_node:, current_index: param_end_index)]
      # end

      return matches.compact
    end

    private

    def next_node(node:, path:)
      return node if node.route&.path == path

      node.nodes()
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
