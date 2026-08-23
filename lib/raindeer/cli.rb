# frozen_string_literal: true

require 'low_node'
require 'low_type'
require 'observers'
require 'providers'

# Allows the CLI to load application code and metadata, but not start a server.

#################################################
# FRAMEWORK INTERNAL API
#################################################

module Rain
  require_relative '../support/config_loader'

  Providers.define('rain.router') do
    require_relative '../router/router'
    Router.new
  end
end

#################################################
# FRAMEWORK EXTERNAL API
#################################################

require_relative 'raindeer'

#################################################
# CLI
#################################################

require_relative '../cli/cli'
