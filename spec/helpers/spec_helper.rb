# frozen_string_literal: true

require 'lowtype'
require 'timecop'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
    # Large diff when expected objects don't match.
    expectations.max_formatted_output_length = 10_000
  end
end

LowType.configure do |config|
  config.output_mode = :value
  config.output_size = 100
end

def render_frames(frames = 100, fps = 10)
  frame_duration = 1.0 / fps

  frames.times do
    system 'clear' if ENV['SHOW_OUTPUT'] == '1'
    yield
    sleep(frame_duration)
  end
end

class Array
  def paint_columns
    map do
      it[1] ? ::Paint[it[0], it[1]] : ::Paint[it[0]]
    end.join(' ')
  end
end

class String
  # Delete whitespace at the start of a new line, then delete new lines.
  def squish
    gsub(/^\s*/, '').delete("\n")
  end
end
