# frozen_string_literal: true

require_relative 'route'
require_relative 'route_event'
require_relative 'trie_node'

module Rain
  class Trie
    include LowType

    PARAM_DELIMITER_PATTERN = %r{[/:]}
    ARG_DELIMITER = '/'
    # Delimiters for STATIC segments only -- capture_arg's delimiter (dynamic param values) is
    # unaffected, so a kebab-case value like "hello-world" still matches a :slug param as one
    # whole piece.
    SEGMENT_DELIMITER_PATTERN = %r{[/\-:]}
    # Byte values of the delimiters, used to dispatch on the current character without
    # allocating a single-character String via path[i] -- String#getbyte returns a plain
    # Integer instead. Safe for these three ASCII delimiters even on multi-byte UTF-8 paths,
    # since ASCII bytes never appear as continuation bytes in a valid UTF-8 sequence.
    SLASH_BYTE = '/'.ord
    HYPHEN_BYTE = '-'.ord
    COLON_BYTE = ':'.ord
    SINGLE_CHAR_SEGMENT_BYTES = [SLASH_BYTE, HYPHEN_BYTE].freeze

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
        key, current_index =
          if path.getbyte(current_index) == COLON_BYTE
            capture_param(current_index:, path:)
          else
            static_segment(current_index:, path:)
          end

        current_node = current_node.upsert_child(key:)
      end

      current_node.route = route
    end

    def match(path:, current_node: @root_node, current_index: 0, params: {})
      route_events = []
      collect_matches(path:, current_node:, current_index:, params:, route_events:)
      route_events
    end

    private

    # Appends to the shared route_events accumulator instead of building and splat-concatenating
    # a new array at every level of recursion -- match() used to be O(path length) array allocations.
    def collect_matches(path:, current_node:, current_index:, params:, route_events:)
      return if path[current_index].nil?

      static_key, static_next_index = static_segment(current_index:, path:)

      if (child_node = current_node.child(key: static_key))
        route_events << route_event(next_index: static_next_index, params:, path:, route: child_node.route) if child_node.route
        collect_matches(path:, current_node: child_node, current_index: static_next_index, params:, route_events:)
      end

      # Dynamic request path segment.
      current_node.params.each do |param|
        child_node = current_node.child(key: param)

        arg, next_index = capture_arg(arg_start_index: current_index, path:)
        params[param.delete_prefix(':').to_sym] = arg

        route_events << route_event(next_index:, params:, path:, route: child_node.route) if child_node.route
        collect_matches(path:, current_node: child_node, current_index: next_index, params:, route_events:)
      end
    end

    # Mid nodes handle events, end nodes render events.
    def route_event(next_index:, params:, path:, route:)
      action = path[next_index].nil? ? :render : :handle
      RouteEvent.new(action:, route:, params:)
    end

    # Scans via String#index instead of decomposing the remaining path into single-character
    # strings with #chars -- same reasoning as capture_segment.
    def capture_param(current_index:, path:)
      current_index += 1
      next_index = path.index(PARAM_DELIMITER_PATTERN, current_index) || path.length

      [":#{path[current_index...next_index]}", next_index]
    end

    def capture_arg(arg_start_index:, path:)
      next_index = path.index(ARG_DELIMITER, arg_start_index) || path.length

      [path[arg_start_index...next_index], next_index]
    end

    # Candidate static key for the request path at current_index, computed with the same
    # segmentation rule merge() uses to build the trie -- this is what makes matching an exact
    # whole-segment match rather than a character-prefix match, e.g. a route registered at
    # "/api" no longer spuriously matches a request for "/apikey".
    def static_segment(current_index:, path:)
      byte = path.getbyte(current_index)

      SINGLE_CHAR_SEGMENT_BYTES.include?(byte) ? [path[current_index], current_index + 1] : capture_segment(current_index:, path:)
    end

    # Captures a whole run of static text as one key, stopping at the next segment delimiter --
    # only called when the current character is already confirmed not to be one, so this never
    # returns an empty segment.
    def capture_segment(current_index:, path:)
      next_index = path.index(SEGMENT_DELIMITER_PATTERN, current_index) || path.length
      [path[current_index...next_index], next_index]
    end
  end
end
