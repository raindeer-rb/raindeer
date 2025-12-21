# frozen_string_literal: true

require 'low_type'
require_relative 'router'

class Raindeer
  class << self
    def router(&)
      @router ||= RainRouter.new
      @router.instance_eval(&block)
    end
  end
end
