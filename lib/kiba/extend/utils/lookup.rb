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
                bool << exclude_on_empty?(mrow, value)
              when :field_equal
                if value.is_a?(Hash)
                  bool << exclude_on_equality?(row, mrow, value)
                else
                  value.each{ |h| bool << exclude_on_equality?(row, mrow, h) }
                  end
              end
            end
            bool.flatten.any? ? true : false
          end

          def exclude_on_empty?(mrow, fields)
            bool = []
            fields.each do |field|
              val = mrow.fetch(field, '')
              bool << true if val.nil? || val.empty?
            end
            bool
          end
          
          def exclude_on_equality?(row, mrow, hash)
            bool = []
            hash.each do |rowfield, mergefield|
              row.fetch(rowfield, '') == mrow.fetch(mergefield, '') ? bool << true : bool << false
            end
            bool
          end
        end
      end
    end
  end
end
