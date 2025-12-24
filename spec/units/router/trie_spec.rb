# frozen_string_literal: true

require_relative '../../../lib/router/route'
require_relative '../../../lib/router/trie'

module Rain
  RSpec.describe Trie do
    subject(:trie) { described_class.new }

    def matching_node(node:, path:)
      return node if node.route&.path == path

      node.nodes.values.map do |child_node|
        matching_node(node: child_node, path:)
      end.compact.first
    end

    describe '#initialize' do
      it 'creates the root path node' do
        expect(trie.root_path_node.route).to have_attributes(path: '/')
      end
    end

    describe '#insert' do
      it 'creates a prefix tree of nodes' do
        trie.insert(route: Route.new(path: '/users'))
        trie.insert(route: Route.new(path: '/users/:id'))
        trie.insert(route: Route.new(path: '/users/:id/edit'))

        expect(trie.root_path_node.nodes.keys.first).to eq('u')
        expect(trie.root_path_node.nodes.values.first.nodes.keys.first).to eq('s')
        expect(trie.root_path_node.nodes.values.first.nodes.values.first.nodes.keys.first).to eq('e')

        expect(matching_node(node: trie.root_path_node, path: '/users')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id/edit')).to be_truthy
      end
    end
  end
end
