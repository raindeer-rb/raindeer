# frozen_string_literal: true

require 'antlers/api'
require_relative '../../../../lib/pages/raindown/elements'

RSpec.describe Antlers::Lexer do
  subject(:lexer) { described_class.new(lexeme_types:) }

  let(:lexeme_types) { Rain::Elements[:toc, :list][:lexeme] }

  describe '.parse' do
    context 'with a toc' do
      let(:template) do
        <<~HTML
          <{ :toc }>

          <h2 id="heading-2">Heading 2</h2>
          <p>Paragraph 2</p>
          <h3 id="heading-3">Heading 3</h3>
          <p>Paragraph 3</p>
        HTML
      end

      it 'returns sequence' do
        expect(lexer.parse(template:)).to eq([[{ toc: 'TODO'}]])
      end
    end

    context 'with a list' do
      let(:template) do
        <<~RUBY
          <{ list: value folder: 'cards' }>
            {value}
          <{ :list }>
        RUBY
      end

      let(:sequence) do
        [{ list_def: 'value', folder: 'cards' }, { var: 'value' }, { list_end: 'level_1' }]
      end

      it 'returns sequence' do
        expect(lexer.parse(template:)).to eq(sequence)
      end

      context 'when wrapped in HTML' do
        let(:template) do
          <<~RUBY
            <html>
              <{ list: item folder: items }>
                {item}
              <{ :list }>
            </html>
          RUBY
        end

        let(:sequence) do
          ['<html>', { list_def: 'item', folder: 'items' }, { var: 'item' }, { list_end: 'level_1' }, '</html>']
        end

        it 'returns sequence' do
          expect(lexer.parse(template:)).to eq(sequence)
        end
      end
    end
  end
end
