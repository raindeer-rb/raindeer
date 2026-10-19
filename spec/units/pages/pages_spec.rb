# frozen_string_literal: true

require 'dirload'
require 'tmpdir'
require_relative '../../../lib/pages/pages'

RSpec.describe Rain::Pages do
  subject(:pages) { described_class.new(metadata: dirload(File.join(@dir, 'app'))) }

  around do |example|
    Dir.mktmpdir do |dir|
      @dir = File.realpath(dir)
      Dir.chdir(dir) { example.run }
    end
  end

  def write(path, content)
    file_path = File.join(@dir, 'app', 'pages', path)
    FileUtils.mkdir_p(File.dirname(file_path))
    File.write(file_path, content)
  end

  before do
    write('docs/_basics/_1-getting-started.md', "---\ntitle: Getting started\n---\n\n# Getting started\n")
    write('docs/_basics/_2-setup.rd', "---\ntitle: Setup\n---\n\n# Setup\n\nfiles: folder: 'basics'\n")
    write('home.md', "# Home\n")
  end

  it 'makes URL paths from the path under app/pages, without underscored segments' do
    expect(described_class.url_path(file_path: "#{described_class.pages_path}/docs/_1&_guides/_10-deploy.md")).to eq('/docs/deploy')
  end

  it 'maps URL paths to files' do
    expect(pages.url_paths.keys).to contain_exactly('/docs/getting-started', '/docs/setup', '/home')
  end

  it "adds each page's URL path to Raindown's metadata as its path" do
    expect(pages.list(folder: 'basics').map { [it.title, it.folder, it.order, it.path] })
      .to eq([['Getting started', 'basics', 1, '/docs/getting-started'], ['Setup', 'basics', 2, '/docs/setup']])
  end

  it 'renders a page by URL path with Raindown, listing files by URL path' do
    page = pages.page(path: '/docs/setup')

    expect(page.metadata).to include(title: 'Setup', path: '/docs/setup')
    expect(page.html).to include('<h1 id="setup">', '<a href="/docs/getting-started">Getting started</a>')
    expect(page.html).to include("<!-- files: folder: 'basics' -->")
    expect(page.html).not_to include('<strong>')
  end

  it "hides directives in a listed page's content, even with a .raindown/config.yml" do
    FileUtils.mkdir_p(File.join(@dir, '.raindown'))
    File.write(File.join(@dir, '.raindown', 'config.yml'), "hide_directives: false\n")

    expect(pages.list(folder: 'basics').last.content).to include("<!-- files: folder: 'basics' -->")
    expect(pages.page(path: '/docs/setup').html).not_to include('<strong>')
  end

  it 'renders the home page for /' do
    expect(pages.page(path: '/').html).to include('<h1 id="home">')
    expect(pages.page(path: '/missing')).to be_nil
  end
end
