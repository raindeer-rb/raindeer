# frozen_string_literal: true

require 'ruby-progressbar'
require 'fileutils'

require 'antlers' # Adds antlers support to lowload.
require 'lowload'

require_relative '../pages/pages'

module Rain
  module CLI
    module Static
      extend self

      FakeRequest = Data.define(:path)
      RequestResult = Data.define(:path, :status, :html)

      def build(application_path:)
        metadata = load_user_application(app_path: File.expand_path('app', application_path))
        build_path = File.expand_path('build', application_path)

        FileUtils.rm_rf(build_path)
        FileUtils.mkdir_p(build_path)
        FileUtils.cp_r(File.expand_path('public', application_path), File.expand_path('public', build_path))

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
        metadata = LowLoad.dirload(app_path)

        if Dir.exist?(File.expand_path('pages', app_path))
          Providers.define('rain.pages', eager: true) do
            require_relative '../pages/pages'
            Rain::Pages.new(metadata:)
          end
        end

        metadata
      end

      def request_results(metadata:)
        file_paths = metadata.file_types.values_at('md', 'rd', 'markdown', 'raindown').flat_map { it }.compact
        paths = file_paths.map { |file_path| Rain::Pages.url_path(file_path:) }.compact
        paths << '/'
        # Skip files that became solely metadata due to underscores hiding the entire file path.
        paths.reject! { |url_path| url_path == '' }

        progress_bar = ProgressBar.create(
          total: paths.size,
          format: "\e[0;34m%a |%B| %p%%\e[0m"
        )

        paths.map do |path|
          request = FakeRequest.new(path:)
          response = Low::Events::RequestEvent.take(request:).response
          result = RequestResult.new(path:, status: response.status, html: response.read)
          progress_bar.increment
          result
        end
      end
    end
  end
end
