# frozen_string_literal: true

require 'tmpdir'
require_relative '../../../lib/assets/assets'

RSpec.describe Rain::Assets do
  subject(:assets) { described_class.new(web_root:, bundles:) }

  # The real path, as file watchers report changes by it (macOS's temp folder is behind a symlink).
  let(:web_root) { File.realpath(Dir.mktmpdir) }
  let(:bundles) do
    {
      'app.css': ['style.css', 'components/cards.css'],
      'app.js': ['components/toc.js']
    }
  end

  before do
    write('style.css', 'body {}')
    write('components/cards.css', '.card {}')
    write('components/toc.js', 'const toc = 1;')
  end

  after { FileUtils.rm_rf(web_root) }

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(File.join(web_root, path)))
    File.write(File.join(web_root, path), content)
  end

  def read(path) = File.read(File.join(web_root, path))
  def labels(path) = read(path).scan(%r{^/\* (.+) \*/$}).flatten

  describe '#build' do
    it 'bundles CSS in the order listed, labelled by file' do
      assets.build

      expect(read('app.css')).to eq("/* style.css */\nbody {}\n\n/* components/cards.css */\n.card {}\n")
    end

    it 'gives each script its own scope' do
      assets.build

      expect(read('app.js')).to eq("// components/toc.js\n(() => {\nconst toc = 1;\n})();\n")
    end

    context 'with wildcards' do
      let(:bundles) { { 'app.css': ['style.css', 'components/*', 'components/*/*'] } }

      before do
        write('components/alerts.css', '.alert {}')
        write('components/sidebar/sidebar.css', '.sidebar {}')
        write('components/sidebar/sidebar.js', 'const sidebar = 1;')
      end

      it 'adds matching files with the bundle extension, alphabetically, level by level' do
        assets.build

        expect(labels('app.css')).to eq(
          %w[style.css components/alerts.css components/cards.css components/sidebar/sidebar.css]
        )
      end

      it 'adds a file once when listed and matched' do
        bundles[:'app.css'].insert(1, 'components/cards.css')
        assets.build

        expect(labels('app.css').count('components/cards.css')).to eq(1)
      end
    end

    context 'with a wildcard that matches the bundle' do
      let(:bundles) { { 'app.css': ['*'] } }

      it 'leaves the bundle out' do
        assets.build
        assets.build

        expect(labels('app.css')).to eq(['style.css'])
      end
    end
  end

  describe '#rebuild' do
    before { assets.build }

    it 'rebuilds bundles that include a changed file' do
      write('style.css', 'html {}')
      assets.rebuild([File.join(web_root, 'style.css')])

      expect(read('app.css')).to include('html {}')
    end

    it 'leaves other bundles alone' do
      write('components/toc.js', 'const toc = 2;')
      assets.rebuild([File.join(web_root, 'style.css')])

      expect(read('app.js')).to include('const toc = 1;')
    end

    it 'ignores a bundle being written' do
      write('style.css', 'html {}')
      assets.rebuild([File.join(web_root, 'app.css')])

      expect(read('app.css')).to include('body {}')
    end

    context 'with wildcards' do
      let(:bundles) { { 'app.css': ['components/*'], 'app.js': ['components/*'] } }

      it 'adds a new matching file' do
        write('components/alerts.css', '.alert {}')
        assets.rebuild([File.join(web_root, 'components/alerts.css')])

        expect(labels('app.css')).to eq(%w[components/alerts.css components/cards.css])
      end

      it 'drops a deleted file' do
        FileUtils.rm(File.join(web_root, 'components/cards.css'))
        assets.rebuild([File.join(web_root, 'components/cards.css')])

        expect(read('app.css')).not_to include('.card {}')
      end

      it 'only rebuilds bundles with the changed file extension' do
        write('components/toc.js', 'const toc = 2;')
        write('components/cards.css', '.card { color: red; }')
        assets.rebuild([File.join(web_root, 'components/toc.js')])

        expect([read('app.js'), read('app.css')]).to contain_exactly(include('const toc = 2;'), include('.card {}'))
      end
    end
  end
end
