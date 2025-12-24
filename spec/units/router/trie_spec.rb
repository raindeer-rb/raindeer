# frozen_string_literal: true

require_relative '../../../lib/router/route'
require_relative '../../../lib/router/trie'

module Rain
  RSpec.describe Trie do
    subject(:trie) { described_class.new }

    describe '#initialize' do
      it 'creates the root path node' do
        expect(trie.nodes['/'].route).to have_attributes(path: '/')
      end
    end
  end
end
