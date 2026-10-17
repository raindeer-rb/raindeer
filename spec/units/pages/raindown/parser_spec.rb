# frozen_string_literal: true

require 'antlers/api'

require_relative '../../../../lib/pages/raindown/elements'
require_relative '../../../../lib/pages/raindown/nodes/list_node'

RSpec.describe Antlers::Parser do
  subject(:parser) { described_class.new(node_types:) }

  let(:node_types) do
    Antlers::Elements[:html, :var][:node] + Rain::Elements[:list][:node]
  end
  let(:var_node) { Antlers::VarNode.new(value: "I'm just a string") }
  let(:prop_node) { Antlers::PropNode.new(name: 'PropNode', props: { prop_with_val: 'mock_val', prop_without_val: nil }) }

  describe '.parse' do
    context 'with list' do
      let(:list_node) do
        Rain::ListNode.new(value: 'value', folder: 'cards', children: [var_node])
      end

      let(:sequence) do
        [{ list_def: 'value', folder: 'cards' }, { var: 'value' }, { list_end: 'level_1' }]
      end

      it 'returns AST' do
        expect(parser.parse(sequence:).children).to eq([list_node])
      end
    end
  end
end
