# frozen_string_literal: true

require 'paint'
require 'lowevent'

require_relative '../../../lib/matrix/matrix'
require_relative '../../../lib/support/config_loader'
require_relative '../../factories/event_factory'
require_relative '../../fixtures/mock_events'

RSpec.describe Rain::Matrix do
  subject(:matrix) { described_class.new(event_pool:, config:) }

  let(:event_pool) { instance_double(Low::Events::EventPool, event_trees:) }
  let(:config) { Rain::ConfigLoader.load('matrix.yaml', overrides) }
  let(:overrides) { {} }
  let(:show_output) { ENV['SHOW_OUTPUT'] == '1' }

  let(:cell_color) { '#0098fc' }
  let(:lead_color) { '#ffffff' }

  before do
    Observers::Keys.reset
  end

  context 'when 1 column' do
    let(:event_trees) do
      {
        1 => Fixtures::EventFactory.request_response_tree(request_id: 1),
        2 => Fixtures::EventFactory.request_response_tree(request_id: 2),
        3 => Fixtures::EventFactory.request_response_tree(request_id: 3)
      }
    end
    let(:screen_size) { { column_count: 1, row_count: 20 } }
    let(:overrides) { { start_col: :random } }

    let(:lines) do
      <<~BASH.delete_prefix("\n").delete_suffix("\n")
        #{[['R', cell_color]].paint_columns}
        #{[['e', cell_color]].paint_columns}
        #{[['q', cell_color]].paint_columns}
        #{[['u', cell_color]].paint_columns}
        #{[['e', cell_color]].paint_columns}
        #{[['s', cell_color]].paint_columns}
        #{[['t', cell_color]].paint_columns}
        #{[['│', cell_color]].paint_columns}
        #{[['▼', cell_color]].paint_columns}
        #{[['R', cell_color]].paint_columns}
        #{[['e', cell_color]].paint_columns}
        #{[['s', cell_color]].paint_columns}
        #{[['p', cell_color]].paint_columns}
        #{[['o', cell_color]].paint_columns}
        #{[['n', cell_color]].paint_columns}
        #{[['s', cell_color]].paint_columns}
        #{[['e', lead_color]].paint_columns}
        #{[[' '            ]].paint_columns}
        #{[[' '            ]].paint_columns}
        #{[[' '            ]].paint_columns}
      BASH
    end

    it 'renders a matrix' do
      render_frames { matrix.render(screen_size:, show_output:) }
      expect { matrix.render(screen_size:) }.to output(lines).to_stdout
    end
  end

  context 'when 2 columns' do
    let(:event_trees) do
      {
        1 => Fixtures::EventFactory.request_response_tree(request_id: 1),
        2 => Fixtures::EventFactory.request_response_tree(request_id: 2),
        3 => Fixtures::EventFactory.request_response_tree(request_id: 3)
      }
    end
    let(:screen_size) { { column_count: 2, row_count: 20 } }

    let(:lines) do
      <<~BASH.delete_prefix("\n").delete_suffix("\n")
        #{[['R', cell_color], ['R', cell_color]].paint_columns}
        #{[['e', cell_color], ['e', cell_color]].paint_columns}
        #{[['q', cell_color], ['q', cell_color]].paint_columns}
        #{[['u', cell_color], ['u', cell_color]].paint_columns}
        #{[['e', cell_color], ['e', cell_color]].paint_columns}
        #{[['s', cell_color], ['s', cell_color]].paint_columns}
        #{[['t', cell_color], ['t', cell_color]].paint_columns}
        #{[['│', cell_color], ['│', cell_color]].paint_columns}
        #{[['▼', cell_color], ['▼', cell_color]].paint_columns}
        #{[['R', cell_color], ['R', cell_color]].paint_columns}
        #{[['e', cell_color], ['e', cell_color]].paint_columns}
        #{[['s', cell_color], ['s', cell_color]].paint_columns}
        #{[['p', cell_color], ['p', cell_color]].paint_columns}
        #{[['o', cell_color], ['o', cell_color]].paint_columns}
        #{[['n', cell_color], ['n', cell_color]].paint_columns}
        #{[['s', cell_color], ['s', cell_color]].paint_columns}
        #{[['e', lead_color], ['e', lead_color]].paint_columns}
        #{[[' '            ], [' '            ]].paint_columns}
        #{[[' '            ], [' '            ]].paint_columns}
        #{[[' '            ], [' '            ]].paint_columns}
      BASH
    end

    it 'renders a matrix' do
      render_frames { matrix.render(screen_size:, show_output:) }
      expect { matrix.render(screen_size:) }.to output(lines).to_stdout
    end
  end

  context 'when events created seconds apart' do
    let(:event_trees) do
      {
        1 => Fixtures::EventFactory.request_response_tree(request_id: 1, created_at: created_at),
        2 => Fixtures::EventFactory.request_response_tree(request_id: 2, created_at: created_at + 1000),
        3 => Fixtures::EventFactory.request_response_tree(request_id: 3, created_at: created_at + 2000)
      }
    end
    let(:created_at) { Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) }
    let(:screen_size) { { column_count: 3, row_count: 20 } }

    let(:lines) do
      <<~BASH.delete_prefix("\n").delete_suffix("\n")
        #{[['R', cell_color], ['R', cell_color], ['R', cell_color]].paint_columns}
        #{[['e', cell_color], ['e', cell_color], ['e', cell_color]].paint_columns}
        #{[['q', cell_color], ['q', cell_color], ['q', cell_color]].paint_columns}
        #{[['u', cell_color], ['u', cell_color], ['u', cell_color]].paint_columns}
        #{[['e', cell_color], ['e', cell_color], ['e', cell_color]].paint_columns}
        #{[['s', cell_color], ['s', cell_color], ['s', cell_color]].paint_columns}
        #{[['t', cell_color], ['t', cell_color], ['t', cell_color]].paint_columns}
        #{[['│', cell_color], ['│', cell_color], ['│', cell_color]].paint_columns}
        #{[['▼', cell_color], ['▼', cell_color], ['▼', cell_color]].paint_columns}
        #{[['R', cell_color], ['R', cell_color], ['R', cell_color]].paint_columns}
        #{[['e', cell_color], ['e', cell_color], ['e', cell_color]].paint_columns}
        #{[['s', cell_color], ['s', cell_color], ['s', cell_color]].paint_columns}
        #{[['p', cell_color], ['p', cell_color], ['p', cell_color]].paint_columns}
        #{[['o', cell_color], ['o', cell_color], ['o', cell_color]].paint_columns}
        #{[['n', cell_color], ['n', cell_color], ['n', cell_color]].paint_columns}
        #{[['s', cell_color], ['s', cell_color], ['s', cell_color]].paint_columns}
        #{[['e', lead_color], ['e', lead_color], ['e', lead_color]].paint_columns}
        #{[[' '            ], [' '            ], [' '            ]].paint_columns}
        #{[[' '            ], [' '            ], [' '            ]].paint_columns}
        #{[[' '            ], [' '            ], [' '            ]].paint_columns}
      BASH
    end

    it 'renders a matrix' do
      render_frames { matrix.render(screen_size:, show_output:) }
      expect { matrix.render(screen_size:) }.to output(lines).to_stdout
    end
  end

  context 'when events fade' do
    let(:event_trees) do
      {
        1 => Fixtures::EventFactory.request_response_tree(request_id: 1, created_at: created_at),
        2 => Fixtures::EventFactory.request_response_tree(request_id: 2, created_at: created_at + 1000),
        3 => Fixtures::EventFactory.request_response_tree(request_id: 3, created_at: created_at + 2000)
      }
    end
    let(:created_at) { Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) }
    let(:overrides) { { fade: true } }
    let(:screen_size) { { column_count: 3, row_count: 20 } }

    let(:lines) do
      <<~BASH.delete_prefix("\n").delete_suffix("\n")
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
        #{[[' '], [' '], [' ']].paint_columns}
      BASH
    end

    it 'renders a matrix with no rows' do
      render_frames(300) { matrix.render(screen_size:, show_output:) }
      expect { matrix.render(screen_size:) }.to output(lines).to_stdout
    end
  end
end
