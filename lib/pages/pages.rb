# frozen_string_literal: true

require 'raindown'

module Rain
  # Generates static site pages and those pages have file paths that match a route "{page.path}".
  # Unlike the Raindown CLI we don't write-back and we hide directives "<{}>" in the html output.
  # This repo's .raindown/config.yml is for its own Markdown/Raindown files, not the static site.
  class Pages < Raindown::Pages
    include LowType

    attr_reader :url_paths

    Page = Struct.new(:metadata, :html)
    RENDER_OPTIONS = { hide_directives: true }.freeze

    def initialize(metadata:)
      @url_paths = {}

      super(metadata:, root: Pages.pages_path, render_options: RENDER_OPTIONS)
    end

    def page(path:)
      path = '/home' if path == '/'
      file_path = @url_paths[path] || return

      Page.new(@metadata[file_path], Raindown.render_file(path: file_path, metadata: self, **RENDER_OPTIONS))
    end

    private

    # Adds the URL path to Raindown's metadata for the file, in place of its file path.
    def implicit_metadata(file_path:)
      url_path = Pages.url_path(file_path:)
      @url_paths[url_path] = file_path unless url_path.empty?

      super.merge(path: url_path)
    end

    class << self
      # Remove segments beginning with "_" and ending with "&", "-" or "/", from the path under app/pages.
      # Example: app/pages/docs/_basics/_1-getting-started.md => /docs/getting-started
      def url_path(file_path:)
        url_path = file_path.delete_prefix(pages_path).split(Regexp.union(['/', '&'])).map do |segment|
          next segment.sub(/^_\d+\W/, '') if segment.match?(/^_\d+\W/)
          next nil if segment.start_with?('_')

          segment
        end.compact.join('/')

        url_path.delete_suffix(File.extname(url_path))
      end

      def pages_path
        File.expand_path('app/pages', Dir.pwd)
      end
    end
  end
end
