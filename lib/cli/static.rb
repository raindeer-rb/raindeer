# frozen_string_literal: true

require 'antlers'
require 'lowload'

require 'async'
require 'async/http/internet'
require 'fileutils'

require_relative '../pages/pages'

module Rain
  module CLI
    module Static
      extend self

      RequestResult = Data.define(:path, :html)

      def build(application_path:)
        metadata = LowLoad.dirload(File.expand_path('app', application_path))

        build_path = File.expand_path('build', application_path)
        FileUtils.rm_rf(build_path)
        FileUtils.mkdir_p(build_path)
        FileUtils.cp_r(File.expand_path('public', application_path), File.expand_path('public', build_path))

        request_paths(metadata:, application_path:).each do |result|
          path = File.expand_path(result.path, build_path)
          FileUtils.mkdir_p(path)
          File.write(File.expand_path('index.html', path), result.html)
        end
      end

      private

      def request_paths(metadata:, application_path:)
        file_paths = metadata.file_types.values_at('md', 'rd', 'markdown', 'raindown').flat_map { it }.compact
        url_paths = file_paths.map { |file_path| Rain::Pages.url_path(file_path:) }.compact
        # Skip files that became solely metadata due to underscores hiding the entire file path.
        url_paths.reject! { |url_path| url_path == '' }

        tasks = url_paths.map do |file_path|
          Async do
            request_path = request_path(application_path:, file_path:)
            request_url = endpoint + request_path

            response = client.get(request_url)
            response_html = response.read
            response.close

            RequestResult.new(path: request_path, html: response_html)
          end
        end

        tasks.map(&:result)
      end

      def request_path(application_path:, file_path:)
        file_path.delete_prefix("#{application_path}/app/pages/")
      end

      def client
        Async::HTTP::Internet.new
      end

      def endpoint
        "http://#{config.host}:#{config.port}/"
      end

      def config
        env = {
          host: ENV.fetch('RAIN_HOST', nil),
          port: ENV.fetch('RAIN_PORT', nil),
          web_root: ENV.fetch('RAIN_WEB_ROOT', nil),
          debug_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_DEBUG', true)),
          matrix_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_MATRIX', nil)),
          mirror_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_MIRROR', nil)),
        }
        config_path = File.expand_path('config/config.yaml', Dir.pwd)
        ConfigLoader.load(config_path, env)
      end
    end
  end
end
