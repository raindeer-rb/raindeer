# frozen_string_literal: true

require 'protocol/http'

module Low
  class RequestFactory
    class << self
      def request(path:, verb: 'GET')
        headers = Protocol::HTTP::Headers[['accept', 'text/html']]

        Protocol::HTTP::Request.new('http', "#{ENV['HOST']}:#{ENV['PORT']}", verb, path, 'http/1.1', headers)
      end
    end
  end
end
