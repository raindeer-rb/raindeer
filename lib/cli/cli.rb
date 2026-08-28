# frozen_string_literal: true

require 'trees'
require_relative 'static'

module Rain
  module CLI
    extend Trees

    TEMPLATE_URL = 'https://github.com/raindeer-rb/raindeer-template'

    line('new :app_name') do |app_name|
      summary { 'Generates a Raindeer application with the specified name.' }
      execute do
        system("git clone #{TEMPLATE_URL} #{app_name}")
        system("cd #{app_name}")
      end
    end

    line('server') do
      summary { 'Starts a Raindeer application. Once run visit http://127.0.0.1:4133' }
      execute { system('bin/server') }
    end

    line('build') do
      summary { 'Exports your static site at "app/pages" to the "build" folder.' }
      execute { Static.build(application_path: Dir.pwd) }
    end
  end
end
