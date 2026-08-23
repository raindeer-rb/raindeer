# frozen_string_literal: true

require 'low_node'
require 'low_type'
require 'observers'
require 'providers'

# The CLI loads user application code and metadata, but doesn't start a server.
#
# Flow:
#   1. bin/rain - Located in raindeer or user application, loads "raindeer/cli" which is available on $PATH.
#   2. lib/raindeer/cli - Boots up a raindeer/user application, suitable for use by the CLI <- YOU ARE HERE.
#   3. lib/cli/cli - Defines CLI then responds to the ARGs given to bin/rain.

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
