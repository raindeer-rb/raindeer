# frozen_string_literal: true

require_relative '../../../lib/support/config_loader'

RSpec.describe Rain::ConfigLoader do
  describe '.parse_integer' do
    it 'converts an environment variable to an integer' do
      expect(described_class.parse_integer('4144')).to eq(4144)
    end

    it 'returns nil so the config file is used' do
      expect(described_class.parse_integer(nil)).to be_nil
    end

    it 'raises for a value that is not an integer' do
      expect { described_class.parse_integer('41a4') }.to raise_error(ArgumentError, 'Expected an integer, got "41a4"')
    end
  end

  describe '.load' do
    it 'overrides the config file port with an integer port' do
      config = described_class.load('config/config.yaml', { port: described_class.parse_integer('4144') })

      expect(config.port).to eq(4144)
    end
  end
end
