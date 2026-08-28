# frozen_string_literal: true

require 'antlers'
require 'nokogiri'

module Rain
  class TOCNode < Antlers::LeafNode
    def initialize(name:, template:)
      super(name:)

      @template = template
    end

    def render(current_binding: nil, parent_binding: nil, slot_node: nil)
      doc = Nokogiri::HTML(@template)

      <<~HTML
        <div class="floating">
          <details id="toc" open>
            <summary>Table of contents</summary>
            <ul>
              #{doc.css('h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]').map do |h|
                "<li class='#{h.name}'><a href='\##{h['id']}'>#{h.text.strip}</a></li>"
              end.join("\n")}
            </ul>
          </details>
        </div>
      HTML
    end

    class << self
      def match?(segment:)
        segment[:toc]
      end

      def build(template:, **)
        new(name: :toc, template:)
      end
    end
  end
end
