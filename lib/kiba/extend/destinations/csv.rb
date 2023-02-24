# frozen_string_literal: true

require 'csv'

module Kiba
  module Extend
    module Destinations
      # An extension of Kiba::Common's CSV destination, adding the
      #   `initial_headers` option
      class CSV
        attr_reader :filename, :csv_options, :csv, :headers

        # @param filename [String] path for writing CSV
        # @param csv_options [Hash] options passable to CSV objects. Refer to
        #   https://rubyapi.org/2.7/o/csv#method-c-new for details
        # @param headers Don't use this
        # @param initial_headers [Array<Symbol>] names of fields in the order
        #   you want them output in the CSV. Any you do not explicitly include
        #   here will be appended in whatever order they got created/processed
        #   in, to the right of the ones named here. **Set in registry entry's
        #   `dest_special_opts`**
        def initialize(filename:, csv_options: nil, headers: nil,
                       initial_headers: [])
          @filename = filename
          @csv_options = csv_options || {}
          @headers = headers
          @initial_headers = initial_headers
        end

        # @return [Array<Symbol>]
        def fields
          return [] unless File.exist?(filename)

          csv ||= ::CSV.open(filename, 'r', **csv_options)
          hdrs = csv.shift.headers
          close
          hdrs
        end

        # @private
        def write(row)
          @csv ||= ::CSV.open(filename, 'wb', **csv_options)
          @headers ||= row.keys
          verify_initial_headers
          order_headers
          @headers_written ||= (csv << headers; true)
          csv << row.fetch_values(*@headers)
        end

        # @private
        def close
          csv&.close
        end

        private

        def header_check_hash
          @initial_headers.map{ |hdr| [hdr, headers.any?(hdr)] }.to_h
        end

        def initial_headers_present?
          header_check_hash.values.all?(true)
        end

        def missing_initial_headers
          header_check_hash.reject{ |hdr, present| present }.keys
        end

        def order_headers
          remainder = @headers - @initial_headers
          @headers = [@initial_headers, remainder].flatten
        end

        def verify_initial_headers
          return if @initial_headers.empty?
          return if initial_headers_present?

          missing = missing_initial_headers

          missing.each do |hdr|
            puts "WARNING: Output data does not contain specified initial header: #{hdr}"
          end
          @initial_headers = @initial_headers - missing
        end
      end
    end
  end
end
