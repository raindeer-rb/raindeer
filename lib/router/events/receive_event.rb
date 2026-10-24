# frozen_string_literal: true

require 'json'
require 'uri'
require_relative 'route_event'

module Rain
  module Events
    # A RouteEvent for a request with a body, which calls the "receive" action.
    class ReceiveEvent < RouteEvent
      attr_reader :request

      def initialize(route:, request:, actions: [], params: Hash | nil)
        super(route:, actions:, params:)

        @request = request
      end

      # The body is a stream that can only be read once, so it's buffered on the request for every event of the request to read.
      def raw_body
        return @raw_body if @raw_body
        return @raw_body = '' unless @request.body

        @request.body = @request.body.finish
        @request.body.rewind
        @raw_body = @request.body.join || ''
      end

      # Form and JSON bodies become a hash with symbol keys, other bodies are the raw string.
      def body
        return @body if defined?(@body) # Also keeps a falsy body like JSON "null".

        @body = case media_type
                when 'application/x-www-form-urlencoded' then URI.decode_www_form(raw_body).to_h.transform_keys(&:to_sym)
                when 'application/json' then JSON.parse(raw_body, symbolize_names: true)
                else raw_body
                end
      end

      private

      def media_type = @request.headers['content-type']&.split(';')&.first&.strip
    end
  end
end
