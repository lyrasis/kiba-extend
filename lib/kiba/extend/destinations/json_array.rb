# frozen_string_literal: true

require "json"

module Kiba
  module Extend
    module Destinations
      # Writes each row as a valid JSON object that is an element in a JSON
      #   array
      #
      # This is simliar to the idea of, but not technically compliant with,
      #   [JSON Lines](https://jsonlines.org/)
      class JsonArray
        include Destinationable

        class << self
          def as_source_class = nil

          def default_file_options = nil

          def options_key = nil

          def path_key = :filename

          def requires_path? = true

          def special_options = []
        end

        # @param filename [String] path for writing JSON file
        def initialize(filename:)
          @filename = filename
          ensure_dir
          @json = []
        end

        # @return [Array<Symbol>]
        def fields
          return [] unless File.exist?(filename)

          JSON.parse(File.read(filename))
            .map(&:keys)
            .flatten
            .uniq
        end

        # @private
        def write(row)
          json << row
        end

        # @private
        def close
          File.open(filename, "w") { |f| f << json.to_json }
        end

        private

        attr_reader :filename, :json
      end
    end
  end
end
