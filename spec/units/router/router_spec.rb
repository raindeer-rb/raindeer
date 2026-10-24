# frozen_string_literal: true

require 'observers'
require 'lowevent'

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

    context 'with verb method' do
      it 'creates a route for each HTTP verb' do
        Rain::HTTP::VERBS.each { |verb| router.public_send(verb, "/#{verb}") }

        expect(Rain::HTTP::VERBS.map { |verb| router.routes["/#{verb}"].verbs }).to eq(Rain::HTTP::VERBS.map { [it] })
      end
    end
  end

  describe '#request' do
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
          expect(router.request(event: request_event)).to be('mock response')
          expect(WildcardObserver).to have_received(:render).with({ event: an_instance_of(Rain::Events::WildcardEvent) })
        end

        context 'with translations' do
          let(:request) do
            Low::Support::RequestFactory.request(path: '/anything').tap { it.headers.add('accept-language', 'es-MX, en;q=0.8') }
          end

          before do
            Antlers::Translations.load({ es: { 'Hello' => 'Hola' } })
            allow(WildcardObserver).to receive(:render) { Antlers::Translations.translate('Hello') }
          end

          after { Antlers::Translations.load({}) }

          it 'renders in the requested locale' do
            expect(router.request(event: request_event)).to eq('Hola')
            expect(Antlers::Translations.locale).to be_nil
          end

          context 'with a response' do
            let(:response) { Protocol::HTTP::Response[200, Protocol::HTTP::Headers.new, ['Hola']] }

            before do
              allow(WildcardObserver).to receive(:render).and_return(Low::Events::ResponseEvent.new(response:))
            end

            it 'varies the response by Accept-Language' do
              router.request(event: request_event)

              expect(response.headers['vary']).to include('accept-language')
            end

            it 'sets the picked language as the Content-Language' do
              router.request(event: request_event)

              expect(response.headers['content-language']).to eq(['es'])
            end

            it 'keeps a Content-Language the response already set' do
              response.headers.add('content-language', 'es-MX')
              router.request(event: request_event)

              expect(response.headers['content-language']).to eq(['es-MX'])
            end

            it "doesn't add language headers without translations" do
              Antlers::Translations.load({})
              router.request(event: request_event)

              expect(response.headers['vary']).to be_nil
              expect(response.headers['content-language']).to be_nil
            end
          end
        end
      end
    end

    context 'with "/users" observer' do
      let(:request) { Low::Support::RequestFactory.request(path: '/users') }

      before do
        class UsersObserver
          include Observers
          observe '/users'
          observe Low::Types::Status[404]
        end

        allow(UsersObserver).to receive(:render).and_return(true)
      end

      context 'with "/users" route' do
        before do
          router.route '/users'
        end

        it 'triggers route event on observer' do
          router.request(event: request_event)
          expect(UsersObserver).to have_received(:render).with({ event: an_instance_of(Rain::Events::RouteEvent) })
        end
      end

      context 'without /users route' do
        let(:request) { Low::Support::RequestFactory.request(path: '/missing-path') }

        it 'triggers status event on observer' do
          router.request(event: request_event)
          expect(UsersObserver).to have_received(:render).with({ event: an_instance_of(Low::Events::StatusEvent) })
        end
      end
    end
  end
end
