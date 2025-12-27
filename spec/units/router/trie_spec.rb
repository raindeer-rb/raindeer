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
      context 'with a static route' do
        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users'))

          expect(trie.match(path: '/users')).to all(be_instance_of(RouteEvent))
          expect(trie.match(path: '/users').first.route).to have_attributes(path: '/users')
        end
      end

      context 'with a static/dynamic route' do
        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users/:id'))

          expect(trie.match(path: '/users/1')).to all(be_instance_of(RouteEvent))
          expect(trie.match(path: '/users/1').first.route).to have_attributes(path: '/users/:id')
        end
      end

      context 'with a dynamic route' do
        context 'when single level' do
          it 'creates a route event' do
            trie.merge(route: Route.new(path: '/:user_id'))

            expect(trie.match(path: '/username').first.route).to have_attributes(path: '/:user_id')
            expect(trie.match(path: '/username').first.params).to eq(user_id: 'username')
          end
        end

        context 'when double level' do
          it 'creates a route event' do
            trie.merge(route: Route.new(path: '/:user_id/:post_id'))

            expect(trie.match(path: '/username/123').first.route).to have_attributes(path: '/:user_id/:post_id')
            expect(trie.match(path: '/username/123').first.params).to eq(user_id: 'username', post_id: '123')
          end
        end
      end

      context 'with overlapping routes' do
        before do
          trie.merge(route: Route.new(path: '/users'))
          trie.merge(route: Route.new(path: '/users/:id'))
        end

        it 'creates multiple route events' do
          expect(trie.match(path: '/users/1')).to all(be_instance_of(RouteEvent))
          expect(trie.match(path: '/users/1').first.route).to have_attributes(path: '/users')
          expect(trie.match(path: '/users/1').last.route).to have_attributes(path: '/users/:id')
        end

        context 'when :param is an end node' do
          it "sets the mid node's event action to #handle" do
            route_event = trie.match(path: '/users/1').first # /users
            expect(route_event).to have_attributes(action: :handle)
          end

          it "sets the end node's event action to #render" do
            route_event = trie.match(path: '/users/1').last # /users/:id
            expect(route_event).to have_attributes(action: :render)
          end

          context 'when :param is a mid node' do
            before do
              trie.merge(route: Route.new(path: '/users/:id/edit'))
            end

            it "sets the mid node's event action to #handle" do
              route_event = trie.match(path: '/users/1/edit')[1] # /users/:id
              expect(route_event).to have_attributes(action: :handle)
            end

            it "sets the end node's event action to #render" do
              route_event = trie.match(path: '/users/1/edit').last # /users/:id/edit
              expect(route_event).to have_attributes(action: :render)
            end
          end
        end
      end
    end
  end
end
