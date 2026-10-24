# frozen_string_literal: true

require 'protocol/http'

module Low
  module Support
    class RequestFactory
      class << self
        def request(path:, verb: 'GET', body: nil)
          headers = Protocol::HTTP::Headers['accept' => 'text/html']
          body = Protocol::HTTP::Body::Buffered.wrap(body) if body

          Protocol::HTTP::Request.new('http', "#{ENV['HOST']}:#{ENV['PORT']}", verb, path, 'http/1.1', headers, body)
        end
      end
    end
  end
end
