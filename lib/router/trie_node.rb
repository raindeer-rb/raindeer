# frozen_string_literal: true

require_relative 'route'

module Rain
  class TrieNode
    include LowType
    using LowType::Syntax

    # TODO: Represent empty hash return value as "{}" rather than "Hash" (https://github.com/low-rb/low_type/issues/16)
    type_accessor nodes: Hash[String => TrieNode] | Hash
    type_accessor route: Route | nil

    def initialize
      @nodes = {}
      @route = nil
    end
  end
end
