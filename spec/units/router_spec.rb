# frozen_string_literal: true

require 'observers'
require_relative '../../lib/router'

RSpec.describe RainRouter do
  subject(:rain_router) { described_class.new }

  it 'defines routes as observable' do
    rain_router.get '/user'
    expect(Observers).to have_received(:observable)

    # require_relative '../fixtures/config/routes'
    # expect(Observers::Observables.observables.count > 0)
  end
end
