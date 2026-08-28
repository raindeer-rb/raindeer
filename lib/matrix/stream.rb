# frozen_string_literal: true

require 'low_event'
require 'observers'

require_relative 'cursor'

module Rain
  class Stream
    include Observers
    attr_reader :index, :inputs, :outputs, :delays, :head_cursor, :tail_cursor

    ARROW = ['│', '▼'].freeze

    def initialize(index:, config:, event_tree:)
      @index = index
      @config = config
      @event_tree = event_tree

      @inputs = []
      @delays = []
      @outputs = []

      @event_cursor = 0
      @head_cursor = Cursor.new
      @tail_cursor = Cursor.new(index: 0)

      @show_cursor = Cursor.new
      @hide_cursor = Cursor.new

      observe event_tree
    end

    # TODO: Use "on :branch do |event|" syntax.
    def branch(event: Low::Events::BranchEvent) # rubocop:disable Lint/UnusedMethodArgument
      redraw(cell_count: @inputs.count)
    end

    # Draw event names onto the current amount of cells in a stream, using cursors. Called when there's a new event.
    #
    #  INPUT DELAY OUTPUT
    # ┌─────┬─────┬─────┐
    # │  R  │  75 │     │ ◀── 2. Tail Cursor begins at index zero or a random starting index.
    # │  e  │  75 │     │        A Head Cursor that wraps around will push the Tail Cursor down to be just beneath it.
    # │  q  │  75 │     │        The Show Cursor will start at the Tail Cursor index.
    # │  u  │  75 │     │
    # │     │  75 │     │ ◀── 1. Head Cursor begins at index zero or a random starting index.
    # │     │  75 │     │        It populates input for every character in an event name.
    # │     │  75 │     │        Then sets a "75" delay for the Show Cursor.
    # └─────┴─────┴─────┘
    def redraw(cell_count:)
      randomize_start_index if first_cell_redraw? && @config.start_row == :random
      resize_cells(cell_count:) if cell_count != @inputs.count

      (@event_cursor...@event_tree.sequence.count).each do |event_index|
        current_event = @event_tree.sequence[event_index]
        past_event = @event_tree.sequence[event_index - 1]

        redraw_event(current_event:, past_event:)
        @event_cursor += 1
      end
    end

    # Render a cell's input as output after a delay, using cursors. Called on every frame.
    #
    #  INPUT DELAY OUTPUT
    # ┌─────┬─────┬─────┐
    # │     │   0 │     │ ◀── 2. Hide Cursor moves the input to the output after a delay.
    # │     │ 250 │  e  │        The nil input replaces the previous output of "R".
    # │     │ 250 │  q  │
    # │     │ 250 │  u  │ ◀── 1. Show Cursor moves the input to the output after a delay.
    # │  e  │  75 │     │        Leaving behind nil input.
    # │  s  │  75 │     │        Then sets a "250" delay for the Hide Cursor.
    # │  t  │  75 │     │
    # └─────┴─────┴─────┘
    def render(duration: nil)
      @show_cursor.increment(delays:, inputs:, duration:) do |index|
        index.zero? ? @inputs.count - 1 : index - 1
        index + 1 >= @inputs.count ? 0 : index + 1

        if @inputs[index]
          @outputs[index] = @inputs[index]
          @delays[index] = @config.fade_delay
          @inputs[index] = nil
        end
      end

      fade(duration:) if @config.fade
    end

    private

    def fade(duration: nil)
      fade_start_delay = rand(5_000..10_000)
      return unless (now - @show_cursor.first_update) >= fade_start_delay || duration

      @hide_cursor.increment(delays:, inputs:, duration:) do |index|
        if @inputs[index].nil? && @outputs[index]
          @outputs[index] = @inputs[index]
          @delays[index] = 0
        end
      end
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end

    # A column of cells representing sequential events.
    # ┌─┐
    # │R│  FIRST EVENT
    # │e│  Each cell will render input as output after a minimum delay (since there's no prior event).
    # │q│
    # │u│
    # │e│
    # │s│
    # │t│
    # └─┘ ◀── Time has passed between events.
    # ┌─┐
    # │││  SECOND EVENT
    # │▼│  The next event has data to work with, it can represent the time it took to get from the previous event to the next.
    # │R│  Each cell will delay render for the larger duration of either:
    # │o│   1. The minimum delay
    # │u│   2. The time elapsed between events divided by the number of cells
    # │t│
    # │e│ ◀── A cursor moves to the next cell after a delay.
    # └─┘
    def redraw_event(current_event:, past_event:)
      variable_delay = variable_delay(current_event:, past_event:)

      characters = event_name(current_event:)
      characters = [*ARROW, *characters] if @event_cursor > 0

      @head_cursor.iterate(inputs: characters, loop_count: @inputs.count) do |index, input|
        @inputs[index] = input
        @delays[index] = first_cell_redraw? ? 0 : variable_delay # Don't add delay to the first cell, looks stuck.

        @tail_cursor.increase_index(loop_count: @inputs.count) if @head_cursor.index == @tail_cursor.index
      end

      @hide_cursor.index = @head_cursor.index # Everything after me is old so it can fade away.
    end

    def variable_delay(current_event:, past_event:)
      if @event_cursor.zero?
        @config.min_delay
      else
        difference = current_event.created_at - past_event.created_at
        difference.zero? ? @config.min_delay : (difference / inputs.count).to_i.clamp(@config.min_delay, nil)
      end
    end

    def event_name(current_event:)
      current_event.class.name.split('::').last.delete_suffix('Event').chars
    end

    def first_cell_redraw?
      @head_cursor.index == -1
    end

    def resize_cells(cell_count:)
      old_index = (@inputs.count - 1).clamp(0, nil)

      @inputs = @inputs.fill(nil, old_index...cell_count)[0...cell_count]
      @outputs = @outputs.fill(nil, old_index...cell_count)[0...cell_count]
      @delays = @delays.fill(@config.min_delay, old_index...cell_count)[0...cell_count]
    end

    def randomize_start_index
      random_index = rand(0..2)

      @head_cursor.index = random_index
      @tail_cursor.index = random_index

      @show_cursor.index = random_index
    end
  end
end
