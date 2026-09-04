# frozen_string_literal: true

require 'commonmarker'
require 'antlers/elements'
require_relative 'elements'

module Rain
  module Raindown
    module_function

    def render(markdown:)
      template = markdown.gsub('<{', '<!-- ANTLERS').gsub('}>', 'ANTLERS -->')

      doc = Commonmarker.parse(template.force_encoding('UTF-8'), options: { extension: { alerts: true }})
      doc.walk do |node|
        if %i[code code_block].include?(node.type)
          node.string_content = node.string_content.gsub('<!-- ANTLERS', '<{').gsub('ANTLERS -->', '}>')
        end
      end

      template = doc.to_html(options: { render: { unsafe: true } })
      template = template.gsub('<!-- ANTLERS', '<{').gsub('ANTLERS -->', '}>')

      return template unless template.include?('<{') || template.include?('{')

      ast = Antlers.ast(template:, elements: Antlers::Elements[:html, :prop] + Rain::Elements[:toc])

      Antlers.render(ast:, current_binding: binding)
    end
  end
end
