# frozen_string_literal: true

require 'antlers/translations'
require 'yaml'

module Rain
  # Loads config/translations.yaml into Antlers and picks a request's locale from its Accept-Language header.
  # The "source_locale" config option is the language templates are written in, used when no other language is requested.
  module Translations
    DEFAULT_SOURCE_LOCALE = 'en'

    module_function

    def load(file_path = File.expand_path('config/translations.yaml', Dir.pwd), source_locale: nil)
      @source_locale = (source_locale || DEFAULT_SOURCE_LOCALE).to_s
      return unless File.exist?(file_path)

      Antlers::Translations.load(YAML.safe_load_file(file_path))
    end

    def source_locale
      @source_locale || DEFAULT_SOURCE_LOCALE
    end

    # The templates' own language can be requested too, so "en,es;q=0.5" renders English templates as written.
    def negotiate(accept_language:, locales: Antlers::Translations.locales)
      locales = [source_locale, *locales.reject { it.casecmp?(source_locale) }]

      requested_locale(accept_language:, locales:) || source_locale
    end

    # The first language in "es-ES,es;q=0.9,en;q=0.8" that has a locale, preferring higher "q" values.
    def requested_locale(accept_language:, locales:)
      return nil if accept_language.nil?

      languages(accept_language:).each do |language|
        tag = language.downcase
        locale = locales.find { it.downcase == tag } || locales.find { it.downcase == tag.split('-').first }
        return locale if locale
      end

      nil
    end

    def languages(accept_language:)
      languages = accept_language.split(',').map { |part| language(part:) }
      languages = languages.reject { |language, q| language.empty? || language == '*' || q <= 0 }

      languages.sort_by.with_index { |(_, q), index| [-q, index] }.map(&:first)
    end

    # "es;q=0.9" => ['es', 0.9]
    def language(part:)
      language, *params = part.split(';').map(&:strip)
      q = params.find { it.start_with?('q=') }&.delete_prefix('q=')

      [language.to_s, q ? q.to_f : 1.0]
    end
  end
end
