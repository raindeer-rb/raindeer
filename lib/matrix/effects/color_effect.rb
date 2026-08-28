# frozen_string_literal: true

require_relative 'effect'

module Rain
  class ColorEffect < Effect
    def render(output:, next_output:, **)
      color = next_output ? @config.cell_color : @config.lead_color

      return Paint[output, '#006ab0'] if @config.leet_keys.invert.key?(output)

      output ? Paint[output, color] : Paint[' ']
    end
  end
end
