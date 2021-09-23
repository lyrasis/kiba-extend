# frozen_string_literal: true

require 'json'

module Kiba
  module Extend
    module Destinations
      # Writes rows to a JSON Lines (aka newline-delimited JSON) file
      # See https://jsonlines.org/
      class JsonLines
        # @param filename [String] path for writing JSON file
        def initialize(filename:)
          @json = []
          @file = open(filename, 'w')
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
