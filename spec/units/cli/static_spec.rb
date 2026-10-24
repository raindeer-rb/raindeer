# frozen_string_literal: true

require_relative '../../../lib/cli/static'

RSpec.describe Rain::CLI::Static do
  describe '.output_path' do
    it 'exports a path to a file' do
      expect(described_class.output_path(build_path: '/build', path: '/docs/nodes')).to eq('/build/docs/nodes.html')
    end

    it 'exports the home page to the index file' do
      expect(described_class.output_path(build_path: '/build', path: '/')).to eq('/build/index.html')
    end
  end
end
