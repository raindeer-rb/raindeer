# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'raindeer'
  spec.version = Raindeer::VERSION
  spec.authors = ['maedi']
  spec.email = ['maediprichard@gmail.com']

  spec.summary = 'Deer to be different'
  spec.description = 'A new Ruby framework. Coming soon...'
  spec.homepage = 'https://codeberg.org/raindeer/raindeer'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://codeberg.org/raindeer/raindeer/src/branch/main'

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('lib/**/*')
  end

  spec.require_paths = ['lib']
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }

  spec.add_dependency 'low_event'
  spec.add_dependency 'low_loop'
  spec.add_dependency 'low_node'
  spec.add_dependency 'low_state'
  spec.add_dependency 'low_type', '~> 1.0'
end
