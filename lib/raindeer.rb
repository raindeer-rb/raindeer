require 'low_type'
require_relative 'router'

class Raindeer
  def router(&)
    Rain::Router::DSL.class_eval(&block)
  end
end
