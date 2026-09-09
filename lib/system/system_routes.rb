# frozen_string_literal: true

Raindeer.router do
  get '/system' do
    get '/events'
    get '/routes'
  end
end
