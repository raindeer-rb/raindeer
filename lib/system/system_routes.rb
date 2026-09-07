# frozen_string_literal: true

Raindeer.router do
  route :get => '/system' do
    route :get => '/events'
    route :get => '/routes'
  end
end
