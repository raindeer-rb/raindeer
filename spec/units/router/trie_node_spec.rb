# frozen_string_literal: true

require_relative '../../../lib/router/route'
require_relative '../../../lib/router/trie_node'

module Rain
  RSpec.describe TrieNode do
    subject(:trie_node) { described_class.new }

    describe '#insert' do
      it 'creates the root path node' do
        trie_node.insert(route: Route.new(path: '/'))

        expect(trie_node.nodes['/'].route).to have_attributes(path: '/')
      end
    end
  end
end
