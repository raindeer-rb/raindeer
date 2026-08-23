# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'raindeer'
  spec.version = Raindeer::VERSION
  spec.authors = ['maedi']
  spec.email = ['maediprichard@gmail.com']

  spec.summary = "An event-driven and compositional web framework that's easy to use. Deer to be different."
  spec.description = <<~TEXT
    Raindeer is an event-driven framework using the dynamic features and latest async improvements in Ruby + some weird ideas, 
    to build a new breed of web application. Each Raindeer component can be used individually in your exisiting application, 
    or all together as a cohesive framework. Deer to be different.
  TEXT

  spec.required_ruby_version = '>= 3.3.0'
  spec.homepage = 'https://github.com/raindeer-rb/raindeer'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/raindeer-rb/raindeer/src/branch/main'
  spec.metadata["mailing_list_uri"]   = "https://www.rubyforum.org/tag/raindeer"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('lib/**/*').select { |f| File.file?(f) }
  end
  spec.require_paths = ['lib']

  spec.bindir = 'bin'
  spec.executables = ['rain']

  spec.add_dependency 'ostruct'
  spec.add_dependency 'paint'
  spec.add_dependency 'commonmarker'
  spec.add_dependency 'rouge'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'ruby-progressbar'

  spec.add_dependency 'low_event', '~> 0.5'
  spec.add_dependency 'lowload', '~> 0.6.2'
  spec.add_dependency 'low_loop', '~> 0.6'
  spec.add_dependency 'low_node'
  spec.add_dependency 'low_state'
  spec.add_dependency 'low_type', '~> 1.0'

  spec.add_dependency 'antlers'
  spec.add_dependency 'expressions'
  spec.add_dependency 'observers'
  spec.add_dependency 'plugs'
  spec.add_dependency 'providers'
end
