# frozen_string_literal: true

require 'lowevent'
require 'lowtype'
require 'observers'
require 'paint'

require_relative 'effects/color_effect'
require_relative 'effects/leet_effect'
require_relative 'stream'
require_relative '../support/config_loader'

module Rain
  class Matrix
    include LowType
    include Observers

    def initialize(event_pool:, config: ConfigLoader.load('matrix.yaml'))
      @event_pool = event_pool
      @config = config
      @effects = [(LeetEffect.new(config:) if config.leet), ColorEffect.new(config:)].compact

      @screen_size = nil

      @last_stream_index = -1
      @streams = {} # TODO: Could be a "stream pool" like event pool (a pool hash).
      @columns = []
    end

    def redraw(screen_size:)
      @setup ||= setup

      @streams.each_value do |stream|
        stream.redraw(cell_count: screen_size[:row_count])
      end
    end

    def render(screen_size:, show_output: true)
      if screen_size != @screen_size
        @screen_size = screen_size
        redraw(screen_size:)
      end

      render_streams(show_output:)
    end

    # TODO: Introduce "on :new_event_tree do |event|" block construct in LowEvent for making event handlers more obvious.
    # TODO: Observers should allow arbitrary params when triggering and observing.
    def new_event_tree(event: Low::Events::EventTree)
      stream = upsert_stream(event_tree: event)
      stream.redraw(cell_count: @screen_size[:row_count])
    end

    private

    def setup
      @event_pool.event_trees.each_value do |event_tree|
        upsert_stream(event_tree:)
      end

      observe @event_pool

      true
    end

    def upsert_stream(event_tree:)
      stream = @streams[event_tree.request_id] ||= Stream.new(index: generate_index, config: @config, event_tree:)
      @columns[stream.index] = stream
      stream
    end

    # Where streams become the final output on the matrix.
    # @columns - A column contains a particular stream
    def render_streams(show_output: true) # rubocop:disable Metrics/AbcSize
      @streams.each_value(&:render)

      return unless show_output

      output = ''.dup

      (0...@screen_size[:row_count]).each do |row_index|
        row_outputs = []

        # Rendering streams can happen before redrawing streams, so @columns may not be populated yet.
        (0...column_count).each do |column_index|
          row_outputs << (@columns[column_index].nil? ? nil : @columns[column_index].outputs[row_index])
        end

        output << "\n" + row_outputs.map.with_index do |output, col_index| # rubocop:disable Style/StringConcatenation
          @effects.reduce(output) do |out, effect|
            next_output = @columns[col_index].nil? ? nil : @columns[col_index].outputs[row_index + 1]
            effect.render(output: out, next_output:, x: row_index, y: col_index)
          end
        end.join(' ')
      end

      system 'clear'
      print output.delete_prefix("\n").delete_suffix("\n")
    end

    def generate_index
      case @config.start_col
      when :random
        rand(0...column_count)
      when :latest
        @last_stream_index += 1
        return @last_stream_index = 0 if @last_stream_index >= column_count

        @last_stream_index
      end
    end

    def column_count
      return @screen_size[:column_count] if @screen_size[:column_count] < 10

      (@screen_size[:column_count] / 2).to_i.clamp(1, nil)
    end
  end
end
