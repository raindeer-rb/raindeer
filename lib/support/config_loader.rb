# frozen_string_literal: true

require 'ostruct'
require 'yaml'

module Rain
  class ConfigLoader
    class << self
      def load(file_path, overrides = {})
        file_path = File.expand_path("config/#{file_path}", Dir.pwd) unless File.exist?(file_path)
        config_file = YAML.safe_load_file(file_path, permitted_classes: [Symbol], symbolize_names: true)

        # Environment variables override config file.
        config_data = config_file.merge(overrides) do |_key, old_value, new_value|
          new_value.nil? ? old_value : new_value
        end

        OpenStruct.new(config_data)
      end

      # Environment variables are strings, so "4133" becomes 4133.
      def parse_integer(value)
        return nil if value.nil?

        Integer(value, 10)
      rescue ArgumentError
        raise ArgumentError, "Expected an integer, got #{value.inspect}"
      end

      def parse_boolean(value)
        return true if value == '1'
        return false if value == '0'

        nil
      end
    end
  end
end
