# frozen_string_literal: true

require 'fileutils'
require 'protocol/http'
require 'ruby-progressbar'

require 'antlers' # Adds antlers support to dirload.
require 'dirload'

require_relative '../pages/pages'

module Rain
  module CLI
    module Static
      extend self

      RequestResult = Data.define(:path, :status, :html)

      def build(application_path:)
        metadata = load_user_application(app_path: File.expand_path('app', application_path))
        build_path = File.expand_path('build', application_path)

        FileUtils.rm_rf(build_path)
        FileUtils.mkdir_p(build_path)
        FileUtils.cp_r("#{File.expand_path('public', application_path)}/.", build_path)

        Low::Events::RequestEvent.define do |observers|
          observers << Providers['rain.router']
        end

        request_results(metadata:).each do |request_result|
          folder_path = File.join(build_path, request_result.path)

          puts "#{folder_path} => #{request_result.status}"

          FileUtils.mkdir_p(folder_path)
          File.write(File.expand_path('index.html', folder_path), request_result.html)
        end
      end

      private

      def load_user_application(app_path:)
        metadata = dirload(app_path)

        if Dir.exist?(File.expand_path('pages', app_path))
          Providers.define('rain.pages', eager: true) do
            require_relative '../pages/pages'
            Rain::Pages.new(metadata:)
          end
        end

        metadata
      end

      def request_results(metadata:)
        paths = request_paths(metadata:)

        progress_bar = ProgressBar.create(
          total: paths.size,
          format: "\e[0;34m%a |%B| %p%%\e[0m"
        )

        paths.map do |path|
          request = Protocol::HTTP::Request.new('http', nil, 'GET', path)
          response = Low::Events::RequestEvent.take(request:).response
          result = RequestResult.new(path:, status: response.status, html: response.read)
          progress_bar.increment
          result
        end
      end

      def request_paths(metadata:)
        file_paths = metadata.file_types.values_at('md', 'rd', 'markdown', 'raindown').flat_map { it }.compact
        paths = file_paths.map { |file_path| Rain::Pages.url_path(file_path:) }.compact
        paths << '/'
        paths.concat(static_routes).uniq!
        # Skip files that became solely metadata due to underscores hiding the entire file path.
        paths.reject { |url_path| url_path == '' }
      end

      # GET routes like '/gems' that don't need a param or wildcard to be requested.
      def static_routes
        routes = Providers['rain.router'].routes.values
        routes.select { |route| route.verbs.include?(Rain::HTTP::GET) && !route.path.match?(/[:*]/) }.map(&:path)
      end
    end
  end
end
