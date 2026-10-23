# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../lib/translations/translations'

RSpec.describe Rain::Translations do
  describe '.load' do
    after { Antlers::Translations.load({}) }

    it 'loads translations from a YAML file' do
      file_path = File.join(Dir.mktmpdir, 'translations.yaml')
      File.write(file_path, "symbols:\n  app_name: 'Raindeer'\nes:\n  'Hello': 'Hola'\n")

      described_class.load(file_path)

      expect(Antlers::Translations.translate('Hello', locale: :es)).to eq('Hola')
      expect(Antlers::Translations.translate(:app_name)).to eq('Raindeer')
    end

    it 'ignores a missing file' do
      expect(described_class.load('missing/translations.yaml')).to be_nil
    end
  end

  describe '.negotiate' do
    let(:locales) { %w[es fr pt-BR] }

    before { described_class.load('missing/translations.yaml') }

    it 'picks the most preferred language with translations' do
      expect(described_class.negotiate(accept_language: 'de;q=0.9,fr;q=0.8,es', locales:)).to eq('es')
    end

    it 'falls back from a region to its language' do
      expect(described_class.negotiate(accept_language: 'es-MX,en;q=0.8', locales:)).to eq('es')
    end

    it 'matches a region exactly' do
      expect(described_class.negotiate(accept_language: 'PT-br', locales:)).to eq('pt-BR')
    end

    it 'ignores rejected languages' do
      expect(described_class.negotiate(accept_language: 'fr;q=0', locales:)).to eq('en')
    end

    context 'with the default locale' do
      it 'picks the templates language when it is preferred' do
        expect(described_class.negotiate(accept_language: 'en,es;q=0.5', locales:)).to eq('en')
      end

      it 'picks the templates language for a region' do
        expect(described_class.negotiate(accept_language: 'en-GB,es;q=0.5', locales:)).to eq('en')
      end

      it 'falls back to the templates language' do
        expect(described_class.negotiate(accept_language: 'de', locales:)).to eq('en')
      end

      it 'falls back to the templates language without a header' do
        expect(described_class.negotiate(accept_language: nil, locales:)).to eq('en')
      end

      it 'falls back to the templates language without translations' do
        expect(described_class.negotiate(accept_language: 'es', locales: [])).to eq('en')
      end
    end

    context 'with a locale config option' do
      before { described_class.load('missing/translations.yaml', source_locale: :de) }

      after { described_class.load('missing/translations.yaml') }

      it 'picks the templates language when it is preferred' do
        expect(described_class.negotiate(accept_language: 'de-AT,es;q=0.5', locales:)).to eq('de')
      end

      it 'falls back to the templates language' do
        expect(described_class.negotiate(accept_language: 'it', locales:)).to eq('de')
      end

      it 'prefers the requested language' do
        expect(described_class.negotiate(accept_language: 'es,de;q=0.5', locales:)).to eq('es')
      end
    end
  end
end
