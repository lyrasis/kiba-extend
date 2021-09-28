# frozen_string_literal: true

require 'csv'

module Kiba
  module Extend
    module Destinations
      # An extension of Kiba::Common's CSV destination, adding the `initial_headers` option
      class CSV
        attr_reader :filename, :csv_options, :csv, :headers

        # @param filename [String] path for writing CSV
        # @param csv_options [Hash] options passable to CSV objects. Refer to
        #   https://rubyapi.org/2.7/o/csv#method-c-new for details
        # @param headers Don't use this
        # @param initial_headers [Array<Symbol>] names of fields in the order you want them output in the
        #   CSV. Any you do not explicitly include here will be appended in whatever order they got
        #   created/processed in, to the right of the ones named here.
        def initialize(filename:, csv_options: nil, headers: nil, initial_headers: [])
          @filename = filename
          @csv_options = csv_options || {}
          @headers = headers
          @initial_headers = initial_headers
        end

        # @private
        def write(row)
          @csv ||= ::CSV.open(filename, 'wb', **csv_options)
          @headers ||= row.keys
          order_headers
          @headers_written ||= (csv << headers; true)
          csv << row.fetch_values(*@headers)
        end

        # @private
        def close
          csv&.close
        end

        private

        def order_headers
          remainder = @headers - @initial_headers
          @headers = [@initial_headers, remainder].flatten
        end
      end
    end
  end
end
