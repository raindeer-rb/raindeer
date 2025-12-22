# frozen_string_literal: true

require 'observers'
require 'low_event' # RequestEvent. TODO: Move to LowLoop.
require_relative '../../lib/router'
require_relative '../factories/request_factory'

RSpec.describe RainRouter do
  subject(:rain_router) { described_class.new }

  before do
    Observers::Observables.reset
    allow(Observers).to receive(:observable)
    allow(Observers::Observables).to receive(:upsert)
  end

  context 'when defining routes' do
    it 'defines routes as observable' do
      rain_router.get '/user'
      expect(Observers::Observables).to have_received(:upsert)
    end

    it 'creates combinations of routes depending on depth' do
      rain_router.route '/users' do
        rain_router.route '/:id'
      end

      expect(rain_router.routes.keys).to eq(['/users', '/users/:id'])
    end
  end

  # context 'when handling events' do
  #   let(:request_event) { Low::RequestEvent.new(request:) }
  #   let(:request) { Low::RequestFactory.request(path: '/user') }

  #   it 'converts a request event to a route event' do
  #     rain_router.get '/user'
  #     RainRouter.handle(event: request_event)
  #   end
  # end
end
