# frozen_string_literal: true

require 'observers'
require 'low_event'

require_relative '../../../lib/router/router'
require_relative '../../factories/request_factory'

RSpec.describe Rain::Router do
  subject(:router) { described_class.new }

  before do
    Observers::Keys.reset
  end

  describe '#route' do
    it 'creates wildcard route' do
      router.get '*'

      expect(router.routes['*']).to have_attributes(path: '*', verbs: ['GET'])
    end

    it 'creates combinatorial routes' do
      router.get '/users' do
        router.get '/:id'
      end

      expect(router.routes['/users']).to have_attributes(path: '/users', verbs: ['GET'])
      expect(router.routes['/users/:id']).to have_attributes(path: '/users/:id', verbs: ['GET'])
    end
  end

  describe '#handle' do
    let(:request_event) { Low::Events::RequestEvent.new(request:) }

    context 'with "/*" route' do
      let(:request) { Low::Support::RequestFactory.request(path: '/anything') }

      before do
        router.get '/*'
      end

      context 'with "/*" observer' do
        before do
          class WildcardRouteObserver
            include Observers
            observe '/*'
          end

          allow(WildcardRouteObserver).to receive(:render).and_return('mock response')
        end

        it 'triggers route event on observer' do
          expect(router.handle(event: request_event)).to be('mock response')
          expect(WildcardRouteObserver).to have_received(:render).with({ event: an_instance_of(Rain::WildcardEvent) })
        end
      end
    end

    context 'with "/users" observer' do
      let(:request) { Low::Support::RequestFactory.request(path: '/users') }

      before do
        class UsersRouteObserver
          include Observers
          observe '/users'
          observe Low::Types::Status[404]
        end

        allow(UsersRouteObserver).to receive(:render).and_return(true)
      end

      context 'with "/users" route' do
        before do
          router.get '/users'
        end

        it 'triggers route event on observer' do
          router.handle(event: request_event)
          expect(UsersRouteObserver).to have_received(:render).with({ event: an_instance_of(Rain::RouteEvent) })
        end
      end

      context 'without /users route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/missing-path') }

        it 'triggers status event on observer' do
          router.handle(event: request_event)
          expect(UsersRouteObserver).to have_received(:render).with({ event: an_instance_of(Low::Events::StatusEvent) })
        end
      end
    end
  end
end
