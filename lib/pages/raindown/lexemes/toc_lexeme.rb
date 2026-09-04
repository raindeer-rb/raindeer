# frozen_string_literal: true

require 'antlers/api'

module Rain
  module TOCLexeme
    include Antlers::Lexeme

    module_function

    KEYWORDS = [':toc'].freeze

    def match?(keywords:, **)
      keywords.keys.include?(':toc')
    end

    def lexeme(**)
      { toc: :default }
    end
  end
end
