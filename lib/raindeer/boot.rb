# frozen_string_literal: true

require 'low_event'
require 'low_node'
require 'low_type'
require 'observers'
require 'providers'

# File paths are relative to the directory where the process is run from, so the app can just require this boot file.

#################################################
# FRAMEWORK INTERNAL API
#################################################

module Rain
  require_relative '../support/config_loader'
  env = {
    host: ENV.fetch('RAIN_HOST', nil),
    port: ENV.fetch('RAIN_PORT', nil),
    web_root: ENV.fetch('RAIN_WEB_ROOT', nil),
    debug_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_DEBUG', true)),
    matrix_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_MATRIX', nil)),
    mirror_mode: ConfigLoader.parse_boolean(ENV.fetch('RAIN_MIRROR', nil))
  }
  config_path = File.expand_path('config/config.yaml', Dir.pwd)
  config = ConfigLoader.load(config_path, env)

  Providers.define('rain.router') do
    require_relative '../router/router'
    Router.new
  end

  Providers.define('rain.matrix') do
    require_relative '../matrix/matrix'
    Matrix.new(event_pool: Providers['low.event.pool'])
  end

  Providers.define('low.loop') do
    require 'low_loop'
    LowLoop.new(config:, router: Providers['rain.router'], renderer: Providers['rain.matrix'])
  end
end

#################################################
# FRAMEWORK EXTERNAL API
#################################################

require_relative 'integrations'
require_relative 'raindeer'

#################################################
# APPLICATION CODE
#################################################

require 'antlers' # Adds antlers support to lowload.
require 'lowload'
LowLoad.dirload(File.expand_path('../system', __dir__))

application_path = File.expand_path('app', Dir.pwd)
return unless Dir.exist?(application_path)

metadata = LowLoad.dirload(application_path)

if Dir.exist?(File.expand_path('pages', application_path))
  Providers.define('rain.pages', eager: true) do
    require_relative '../pages/pages'
    Rain::Pages.new(metadata:)
  end
end
