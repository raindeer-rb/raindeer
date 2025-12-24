# frozen_string_literal: true

require_relative '../lib/raindeer'

Raindeer.router do
  get '/users' do
    get '/:id'
  end
end
