# frozen_string_literal: true

require_relative '../../../lib/router/route'
require_relative '../../../lib/router/route_event'
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

    describe '#merge' do
      it 'creates the root path node' do
        trie.merge(route: Route.new(path: '/'))
        expect(trie.root_path_node.route).to have_attributes(path: '/')
      end

      it 'creates a prefix tree of nodes' do
        trie.merge(route: Route.new(path: '/users'))
        trie.merge(route: Route.new(path: '/users/:id'))
        trie.merge(route: Route.new(path: '/users/:id/edit'))

        expect(trie.root_path_node.nodes.keys.first).to eq('u')
        expect(trie.root_path_node.nodes.values.first.nodes.keys.first).to eq('s')
        expect(trie.root_path_node.nodes.values.first.nodes.values.first.nodes.keys.first).to eq('e')

        expect(matching_node(node: trie.root_path_node, path: '/users')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id/edit')).to be_truthy
      end
    end

    describe '#match' do
      context 'when route is static' do
        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users'))

          expect(trie.match(path: '/users')).to all(be_instance_of(RouteEvent))
          expect(trie.match(path: '/users').first.route).to have_attributes(path: '/users')
        end
      end

      context 'when route is dynamic' do
        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users/:id'))

          expect(trie.match(path: '/users/1')).to all(be_instance_of(RouteEvent))
          expect(trie.match(path: '/users/1').first.route).to have_attributes(path: '/users/:id')
        end
      end

      context 'when multiple routes overlap' do
        before do
          trie.merge(route: Route.new(path: '/users'))
          trie.merge(route: Route.new(path: '/users/:id'))
        end

        it 'creates multiple route events' do
          expect(trie.match(path: '/users/1')).to all(be_instance_of(RouteEvent))
          expect(trie.match(path: '/users/1')[0].route).to have_attributes(path: '/users')
          expect(trie.match(path: '/users/1')[1].route).to have_attributes(path: '/users/:id')
        end

        it 'sets the event action for the route end node to #render' do
          expect(trie.match(path: '/users/1')[0]).to have_attributes(action: :handle) # /users
          expect(trie.match(path: '/users/1')[1]).to have_attributes(action: :render) # /users/:id
        end
      end
    end
  end
end
