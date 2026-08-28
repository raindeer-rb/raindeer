# frozen_string_literal: true

require_relative 'raindown/raindown'

module Rain
  class Pages
    include LowType

    attr_reader :url_paths

    Page = Struct.new(:metadata, :html)

    def initialize(metadata:)
      @file_paths = metadata.file_types.values_at('md', 'rd', 'markdown', 'raindown').flat_map { it }.compact
      @url_paths = {}
      @tags = {}

      process_files
    end

    def page(path:)
      path = '/home' if path == '/'
      file_path = @url_paths[path] || return

      metadata, markdown = parse_file(file_path:)
      raindown = Raindown.render(markdown:)

      Page.new(metadata, raindown)
    end

    def list(**typed_tags)
      file_paths = tagged(**typed_tags)
      sorted_paths = file_paths.sort_by { order(it) }
      sorted_paths.map { |file_path| present_file(file_path:) }
    end

    def tagged(**typed_tags)
      file_paths = []

      typed_tags.each do |type, tag|
        file_paths = [*file_paths, *@tags.dig(type, tag)]
      end

      file_paths
    end

    private

    def process_files
      @file_paths.each do |file_path|
        url_path = Pages.url_path(file_path:)
        @url_paths[url_path] = file_path unless url_path.empty?

        tag(type: :folder, tag: folders(file_path:).last, file_path:)

        metadata, * = parse_file(file_path:, parse_content: false)
        metadata.each do |type, tag|
          tag(type:, tag:, file_path:)
        end
      end
    end

    def tag(type:, tag:, file_path:)
      @tags[type] ||= {}
      @tags[type][tag] ||= []
      @tags[type][tag] << file_path
    end

    def folders(file_path:)
      File.dirname(file_path)
          .split(Regexp.union(['/', '&', '-']))
          .filter { it.start_with?('_') }
          .map { it.delete_prefix('_') }
          .filter { !number?(it) }
    end

    def order(file_path)
      file_path
        .split(Regexp.union(['/', '&', '-']))
        .filter { it.start_with?('_') }
        .map { it.delete_prefix('_') }
        .filter { number?(it) }
        .last
    end

    def number?(string)
      !Float(string, exception: false).nil?
    end

    def present_file(file_path:)
      metadata, markdown = parse_file(file_path:)
      metadata[:content] = markdown.empty? ? '' : Raindown.render(markdown:)
      metadata[:path] = Pages.url_path(file_path:)

      OpenStruct.new(metadata)
    end

    def parse_file(file_path:, parse_content: true)
      dash_lines = []
      data_lines = []
      text_lines = []

      File.foreach(file_path) do |line|
        if line.strip == '---' && dash_lines.count < 2
          dash_lines << line
          next
        elsif dash_lines.count > 0 && dash_lines.count < 2
          data_lines << line
          next
        end

        break unless parse_content

        text_lines << line
      end

      [YAML.safe_load(data_lines.join, symbolize_names: true), text_lines.join.strip]
    end

    class << self
      # Remove segments beginning with "_" and ending with "&", "-" or "/".
      # Example: app/pages/docs/_basics/_1-getting-started.md => app/pages/docs/getting-started.md
      def url_path(file_path:)
        url_path = file_path.split(Regexp.union(['/', '&'])).map do |segment|
          next segment.sub(/^_\d\W/, '') if segment.sub(/^_\d\W/, '') != segment
          next nil if segment.sub(/^_/, '') != segment

          segment
        end.compact.join('/')

        url_path.delete_prefix(pages_path).delete_suffix(File.extname(url_path))
      end

      def pages_path
        File.expand_path('app/pages', Dir.pwd)
      end
    end
  end
end
