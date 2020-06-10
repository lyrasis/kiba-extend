module Kiba
  module Extend
    module Utils
      module Lookup
        ::Lookup = Kiba::Extend::Utils::Lookup
        # use when keycolumn values are unique
        # creates hash with keycolumn value as key and csv-row-as-hash as the value
        def self.csv_to_hash(file:, csvopt: {}, keycolumn:)
          CSV.foreach(File.expand_path(file), csvopt).each_with_object({}) do |r, memo|
            memo[r.fetch(keycolumn)] = r.to_h
          end
        end

        # use when keycolumn values are not unique
        # creates hash with keycolumn value as key and array of csv-rows-as-hashes as the value
        def self.csv_to_multi_hash(file:, csvopt: {}, keycolumn:)
          CSV.foreach(File.expand_path(file), csvopt).each_with_object({}) do |r, memo|
            k = r.fetch(keycolumn)
            if memo.has_key?(k)
              memo[k] << r.to_h
            else
              memo[k] = [r.to_h]
            end
          end
        end

        class RowSelector
          def initialize(origrow:, mergerows:, exclude: {}, include: {})
            @exclude = exclude
            @include = include

            @keeprows = mergerows
            @keeprows = mergerows.reject{ |mrow| exclude?(origrow, mrow) }
            if @keeprows.size > 0 && @include.dig(:position) == 'first'
              @keeprows = [@keeprows.first]
            end
            @keeprows = @keeprows.select{ |mrow| include?(origrow, mrow) }
          end

          def result
            @keeprows
          end

          private
          
          def exclude?(row, mrow)
            bool = [false]
            @exclude.each do |type, value|
              case type
              when :field_empty
                bool << is_empty?(mrow, value)
              when :field_equal
                value.each{ |pair| bool << is_equal?(row, mrow, pair) }
              end
            end
            bool.flatten.any? ? true : false
          end

          def include?(row, mrow)
            bool = []
            @include.each do |type, value|
              case type
              when :position
                #do nothing
              when :field_equal
                value.each{ |pair| bool << is_equal?(row, mrow, pair) }
              end
            end
            bool.include?(false) ? false : true
          end
          
          def is_empty?(mrow, fields)
            bool = []
            fields.each do |field|
              val = mrow.fetch(field, '')
              bool << true if val.nil? || val.empty?
            end
            bool
          end
          
          def is_equal?(row, mrow, pair)
            pair = pair.map{ |e| e.split('::') }
            # convert row or mergerow fieldnames to symbols
            pair = pair.each{ |arr| arr[1] = arr[1].to_sym if arr[0]['row'] }
            # fetch or convert values for comparison
            pair = pair.map do |arr|
              case arr[0]
              when 'row'
                row.fetch(arr[1])
              when 'mergerow'
                mrow.fetch(arr[1])
              when 'revalue'
                Regexp.new(arr[1])
              when 'value'
                arr[1]
              end
            end
            pair[0].match?(pair[1])
          end
        end
      end
    end
  end
end
