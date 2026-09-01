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

      it 'creates a prefix tree of nodes, sharing prefixes split on "/" and "-"' do
        trie.merge(route: Route.new(path: '/users'))
        trie.merge(route: Route.new(path: '/users/:id'))
        trie.merge(route: Route.new(path: '/users/:id/edit'))
        trie.merge(route: Route.new(path: '/user-profile'))
        trie.merge(route: Route.new(path: '/user-settings'))

        expect(trie.root_path_node.nodes.keys.first).to eq('users')
        expect(trie.root_path_node.nodes.values.first.nodes.keys.first).to eq('/')
        expect(trie.root_path_node.nodes.values.first.nodes.values.first.nodes.keys.first).to eq(':id')
        expect(trie.root_path_node.nodes['user'].nodes['-'].nodes.keys).to contain_exactly('profile', 'settings')

        expect(matching_node(node: trie.root_path_node, path: '/users')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/users/:id/edit')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/user-profile')).to be_truthy
        expect(matching_node(node: trie.root_path_node, path: '/user-settings')).to be_truthy
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

      it 'requires an exact segment match and keeps hyphenated dynamic values intact' do
        trie.merge(route: Route.new(path: '/api'))
        trie.merge(route: Route.new(path: '/user-profile'))
        trie.merge(route: Route.new(path: '/posts/:slug'))

        expect(trie.match(path: '/apikey')).to eq([])
        expect(trie.match(path: '/user-profile').first.route).to have_attributes(path: '/user-profile')
        expect(trie.match(path: '/posts/hello-world').first.params).to eq(slug: 'hello-world')
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
            # /users
            route_event = trie.match(path: '/users/1').first
            expect(route_event).to have_attributes(action: :handle)
          end

          it "sets the end node's event action to #render" do
            # /users/:id
            route_event = trie.match(path: '/users/1').last
            expect(route_event).to have_attributes(action: :render)
          end

          context 'when :param is a mid node' do
            before do
              trie.merge(route: Route.new(path: '/users/:id/edit'))
            end

            it "sets the mid node's event action to #handle" do
              # /users/:id
              route_event = trie.match(path: '/users/1/edit')[1]
              expect(route_event).to have_attributes(action: :handle)
            end

            it "sets the end node's event action to #render" do
              # /users/:id/edit
              route_event = trie.match(path: '/users/1/edit').last
              expect(route_event).to have_attributes(action: :render)
            end
          end
        end
      end
    end
  end
end
