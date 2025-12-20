# frozen_string_literal: true

require 'observers'
require_relative '../../lib/router'

RSpec.describe Rain::Router do
  subject(:rain_router) { described_class.new }

  it 'defines routes' do
    require_relative '../fixtures/config/routes'
    expect(Observers::Observables.observables.count > 0)
  end
end
