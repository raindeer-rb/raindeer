# frozen_string_literal: true

require_relative 'route'
require_relative 'route_event'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    PARAM_DELIMITERS = ['/', ':'].freeze
    ARG_DELIMITERS = ['/'].freeze

    attr_reader :root_node

    def initialize
      @root_node = TrieNode.new
    end

    def root_path_node
      @root_node.nodes['/']
    end

    def merge(route:, current_node: @root_node, current_index: 0)
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

    def match(path:, current_node: @root_node, current_index: 0, params: {})
      return [] if (key = path[current_index]).nil?

      route_events = []

      # Static path portion.
      if (child_node = current_node.child(key:))
        route_events << RouteEvent.new(route: child_node.route, params:) if child_node.route
        route_events = [*route_events, *match(path:, current_node: child_node, current_index: current_index + 1, params:)]
      end

      # Dynamic path portion.
      current_node.params.each do |param|
        child_node = current_node.child(key: param)

        arg, next_index = capture_arg(arg_start_index: current_index, path:)
        params[param] = arg

        # TODO: This is the end node but we need events for dynamic routes along the way too.
        route_events << RouteEvent.new(action: :render, route: child_node.route, params:) if child_node.route && path[next_index].nil?
        route_events = [*route_events, *match(path:, current_node:, current_index: next_index, params:)]
      end

      route_events
    end

    private

    def next_node(node:, path:)
      return node if node.route&.path == path

      node.nodes
    end

    def capture_param(current_index:, path:)
      current_index += 1
      param = [':']

      path[current_index...path.length].chars.each do |char|
        break if PARAM_DELIMITERS.include?(char)

        current_index += 1
        param << char
      end

      [param.join, current_index]
    end

    def capture_arg(arg_start_index:, path:)
      next_index = arg_start_index
      arg = []

      path[arg_start_index...path.length].chars.each do |char|
        arg << char
        next_index += 1
        break if path[next_index].nil? || ARG_DELIMITERS.include?(path[next_index])
      end

      [arg.join, next_index]
    end
  end
end
