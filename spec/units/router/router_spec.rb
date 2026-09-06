# frozen_string_literal: true

require 'observers'
require 'low_event'

require_relative '../../../lib/router/http'
require_relative '../../../lib/router/router'
require_relative '../../factories/request_factory'

include Rain::HTTP

RSpec.describe Rain::Router do
  subject(:router) { described_class.new }

  before do
    Observers::Keys.reset
  end

  describe '#route' do
    context 'with path' do
      it 'creates wildcard route' do
        router.route '/*'

        expect(router.routes['/*']).to have_attributes(path: '/*', verbs: Rain::HTTP::VERBS)
      end

      it 'creates combinatorial routes' do
        router.route '/users' do
          router.route '/:id'
        end

        expect(router.routes['/users']).to have_attributes(path: '/users', verbs: Rain::HTTP::VERBS)
        expect(router.routes['/users/:id']).to have_attributes(path: '/users/:id', verbs: Rain::HTTP::VERBS)
      end
    end

    context 'with verb => path' do
      it 'creates GET wildcard route' do
        router.route GET => '/*'

        expect(router.routes['/*']).to have_attributes(path: '/*', verbs: [:get])
      end

      it 'creates GET/POST combinatorial routes without mixing up HTTP Verbs' do
        router.route [GET, POST] => '/users' do
          router.route GET => '/:id'
        end

        expect(router.routes['/users']).to have_attributes(path: '/users', verbs: [:get, :post])
        expect(router.routes['/users/:id']).to have_attributes(path: '/users/:id', verbs: [:get])
      end
    end
  end

  describe '#route_request' do
    let(:request_event) { Low::Events::RequestEvent.new(request:) }

    context 'with "/*" route' do
      let(:request) { Low::Support::RequestFactory.request(path: '/anything') }

      before do
        router.route '/*'
      end

      context 'with "/*" observer' do
        before do
          class WildcardObserver
            include Observers
            observe '/*'
          end

          allow(WildcardObserver).to receive(:render).and_return('mock response')
        end

        it 'triggers wildcard event on observer' do
          expect(router.route_request(event: request_event)).to be('mock response')
          expect(WildcardObserver).to have_received(:render).with({ event: an_instance_of(Rain::WildcardEvent) })
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
          router.route '/users'
        end

        it 'triggers route event on observer' do
          router.route_request(event: request_event)
          expect(UsersRouteObserver).to have_received(:render).with({ event: an_instance_of(Rain::RouteEvent) })
        end
      end

      context 'without /users route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/missing-path') }

        it 'triggers status event on observer' do
          router.route_request(event: request_event)
          expect(UsersRouteObserver).to have_received(:render).with({ event: an_instance_of(Low::Events::StatusEvent) })
        end
      end
    end
  end
end
