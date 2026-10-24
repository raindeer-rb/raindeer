# frozen_string_literal: true

require 'protocol/http'
require_relative '../../../lib/router/events/receive_event'
require_relative '../../../lib/router/route'

module Rain
  module Events
    RSpec.describe ReceiveEvent do
      subject(:event) { described_class.new(route: Route.new(path: '/feedback'), request:, actions: %i[receive post]) }

      let(:request) do
        headers = Protocol::HTTP::Headers[content_type ? { 'content-type' => content_type } : {}]
        Protocol::HTTP::Request.new('http', nil, 'POST', '/feedback', nil, headers, Protocol::HTTP::Body::Buffered.wrap(raw_body))
      end
      let(:content_type) { nil }
      let(:raw_body) { '' }

      it 'is a route event' do
        expect(event).to be_a(RouteEvent)
      end

      context 'with a form body' do
        let(:content_type) { 'application/x-www-form-urlencoded; charset=utf-8' }
        let(:raw_body) { 'name=Rudolph&nose=red' }

        it 'parses the body into a hash' do
          expect(event.body).to eq({ name: 'Rudolph', nose: 'red' })
        end
      end

      context 'with a JSON body' do
        let(:content_type) { 'application/json' }
        let(:raw_body) { '{"attributes":{"name":"Rudolph"}}' }

        it 'parses the body into a hash' do
          expect(event.body).to eq({ attributes: { name: 'Rudolph' } })
        end
      end

      context 'with a JSON null body' do
        let(:content_type) { 'application/json' }
        let(:raw_body) { 'null' }

        it 'parses the body once' do
          allow(JSON).to receive(:parse).and_call_original

          expect([event.body, event.body]).to eq([nil, nil])
          expect(JSON).to have_received(:parse).once
        end
      end

      context 'with another body' do
        let(:content_type) { 'text/plain' }
        let(:raw_body) { 'Deer to be different' }

        it 'is the raw body' do
          expect(event.body).to eq('Deer to be different')
        end
      end

      context 'when the body is read more than once' do
        let(:raw_body) { 'once' }

        it 'keeps the body' do
          expect([event.raw_body, event.raw_body, event.body]).to eq(%w[once once once])
        end

        it 'lets other events for the request read the body' do
          other_event = described_class.new(route: Route.new(path: '/:page'), request:)

          expect([event.raw_body, other_event.raw_body]).to eq(%w[once once])
        end
      end

      context 'without a body' do
        let(:request) { Protocol::HTTP::Request.new('http', nil, 'POST', '/feedback', nil, Protocol::HTTP::Headers.new, nil) }

        it 'is empty' do
          expect(event.body).to eq('')
        end
      end
    end
  end
end
