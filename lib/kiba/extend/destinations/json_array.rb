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
          @json = []
          @file = File.open(filename, "w")
        end

        # @private
        def write(row)
          @json << row
        end

        # @private
        def close
          @file << @json.to_json
          @file.close
        end
      end
    end
  end
end
