# frozen_string_literal: true

require 'antlers/api'

module Rain
  module ListLexeme
    include Antlers::Lexeme

    module_function

    KEYWORDS = ['list:', 'order:', ':list'].freeze

    def match?(keywords:, **)
      KEYWORDS.include?(keywords.keys.first)
    end

    def lexeme(keywords:, **)
      if keywords['list:']
        *key, value = keywords['list:'].split(',').map(&:strip)
        list_def = { list_def: value, order: keywords['order:'] }
        list_def[:key] = key.first unless key.empty?
        return list_def
      end

      # TODO: Keep track of which list loop we're in to allow nested list loops.
      { list_end: 'level_1' }
    end
  end
end
