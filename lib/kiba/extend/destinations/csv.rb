require 'csv'

module Kiba
  module Extend
    module Destinations
      class CSV
        attr_reader :filename, :csv_options, :csv, :headers

        def initialize(filename:, csv_options: nil, headers: nil, initial_headers: [])
          @filename = filename
          @csv_options = csv_options || {}
          @headers = headers
          @initial_headers = initial_headers
        end

        def write(row)
          @csv ||= ::CSV.open(filename, 'wb', csv_options)
          @headers ||= row.keys
          order_headers
          @headers_written ||= (csv << headers; true)
          csv << row.fetch_values(*@headers)
        end

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
