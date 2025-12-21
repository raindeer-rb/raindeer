# frozen_string_literal: true

require 'observers'
require_relative '../../lib/router'

RSpec.describe RainRouter do
  subject(:rain_router) { described_class.new }

  before do
    Observers::Observables.reset
    allow(Observers).to receive(:observable)
    allow(Observers::Observables).to receive(:upsert)
  end

  it 'defines routes as observable' do
    rain_router.get '/user'
    expect(Observers::Observables).to have_received(:upsert)
  end
end
