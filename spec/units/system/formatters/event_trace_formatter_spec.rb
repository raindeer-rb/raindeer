# frozen_string_literal: true

require 'observers'
require 'low_node'
require 'lowload'
require 'antlers' # lownode doesn't automatically require antlers.

LowLoad.lowload(File.join(Dir.pwd, '/lib/system/formatters/event_trace_formatter.rbx'))

require_relative '../../../factories/request_factory'

RSpec.describe EventTraceFormatter do
  subject(:output) { described_class.render(event: :dummy, event_tree:).response.body.read }

  let(:request) { Low::Support::RequestFactory.request(path: '/') }

  context 'when the event tree is rooted at a real request' do
    let(:event_tree) do
      tree = Low::Events::EventTree.new(request_id: 'test-1')
      tree.branch(event: Low::Events::RequestEvent.new(request:))
      tree.branch(event: Low::Events::ResponseEvent.new)
      tree
    end

    it 'headings with the request method and path' do
      expect(output).to include('GET /')
    end

    it 'lists every event in the tree, in order' do
      expect(output).to include('Low::Events::RequestEvent')
      expect(output).to include('Low::Events::ResponseEvent')
    end
  end

  context 'when the tree includes a status event (e.g. a 404)' do
    let(:event_tree) do
      tree = Low::Events::EventTree.new(request_id: 'test-2')
      tree.branch(event: Low::Events::RequestEvent.new(request:))
      tree.branch(event: Low::Events::StatusEvent.new(status: Low::Types::Status[404], request:))
      tree
    end

    it 'renders a human-readable status label instead of raw object inspection' do
      expect(output).to include('Status 404')
      expect(output).not_to include('#<Low::Types::Status::StatusCode')
    end
  end
end
