# frozen_string_literal: true

require_relative '../../factories/request_factory'
require_relative '../../../lib/router/events/route_event'
require_relative '../../../lib/router/route'
require_relative '../../../lib/router/trie'

module Rain
  RSpec.describe Trie do
    subject(:trie) { described_class.new }

    describe '#match' do
      before do
        trie.merge(route: Route.new(path: '/feedback'))
      end

      context 'with a request body' do
        let(:request) { Low::Support::RequestFactory.request(path: '/feedback', verb: 'POST', body: 'a=1') }

        it 'creates a route event that receives' do
          expect(trie.match(request:).first.actions).to eq(%i[receive post])
        end
      end

      context 'without a request body' do
        let(:request) { Low::Support::RequestFactory.request(path: '/feedback', verb: 'POST') }

        it 'creates a route event that renders' do
          expect(trie.match(request:).first.actions).to eq(%i[render post])
        end
      end
    end
  end
end
