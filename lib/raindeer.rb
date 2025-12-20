require 'low_type'

require_relative 'rain_router'

class Raindeer
  def routes(&)
    Rain::Router::DSL.class_eval(&)
  end
end
