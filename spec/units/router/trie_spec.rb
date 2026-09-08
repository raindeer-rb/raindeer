# frozen_string_literal: true

require_relative '../../factories/request_factory'
require_relative '../../../lib/router/events/route_event'
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
        let(:request) { Low::Support::RequestFactory.request(path: '/users', verb: 'GET') }

        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users'))

          expect(trie.match(request:)).to all(be_instance_of(RouteEvent))
          expect(trie.match(request:).first.route).to have_attributes(path: '/users')
        end
      end

      context 'with a static/dynamic route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/users/1', verb: 'GET') }

        it 'creates a route event' do
          trie.merge(route: Route.new(path: '/users/:id'))

          expect(trie.match(request:)).to all(be_instance_of(RouteEvent))
          expect(trie.match(request:).first.route).to have_attributes(path: '/users/:id')
        end
      end

      context 'with a dynamic route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/username', verb: 'GET') }

        context 'when single level' do
          it 'creates a route event' do
            trie.merge(route: Route.new(path: '/:user_id'))

            expect(trie.match(request:).first.route).to have_attributes(path: '/:user_id')
            expect(trie.match(request:).first.params).to eq(user_id: 'username')
          end
        end

        context 'when double level' do
          let(:request) { Low::Support::RequestFactory.request(path: '/username/123', verb: 'GET') }

          it 'creates a route event' do
            trie.merge(route: Route.new(path: '/:user_id/:post_id'))

            expect(trie.match(request:).first.route).to have_attributes(path: '/:user_id/:post_id')
            expect(trie.match(request:).first.params).to eq(user_id: 'username', post_id: '123')
          end
        end
      end

      context 'with overlapping routes' do
        let(:request) { Low::Support::RequestFactory.request(path: '/users/1', verb: 'GET') }

        before do
          trie.merge(route: Route.new(path: '/users'))
          trie.merge(route: Route.new(path: '/users/:id'))
        end

        it 'creates multiple route events' do
          expect(trie.match(request:)).to all(be_instance_of(RouteEvent))
          expect(trie.match(request:).first.route).to have_attributes(path: '/users')
          expect(trie.match(request:).last.route).to have_attributes(path: '/users/:id')
        end

        context 'when :param is an end node' do
          let(:request) { Low::Support::RequestFactory.request(path: '/users/1', verb: 'GET') }

          it "sets the mid node's event action to #side_effect" do
            # /users
            route_event = trie.match(request:).first
            expect(route_event).to have_attributes(actions: [:side_effect, :get])
          end

          it "sets the end node's event action to #render" do
            route_event = trie.match(request:).last # => /users/:id
            expect(route_event).to have_attributes(actions: [:render, :get])
          end

          context 'when :param is a mid node' do
            let(:request) { Low::Support::RequestFactory.request(path: '/users/1/edit', verb: 'GET') }

            before do
              trie.merge(route: Route.new(path: '/users/:id/edit'))
            end

            it "sets the mid node's event action to #side_effect" do
              route_event = trie.match(request:)[1] # => /users/:id
              expect(route_event).to have_attributes(actions: [:side_effect, :get])
            end

            it "sets the end node's event action to #render" do
              route_event = trie.match(request:).last # => /users/:id/edit
              expect(route_event).to have_attributes(actions: [:render, :get])
            end
          end
        end
      end
    end
  end
end
