module Kiba
  module Extend
    module Transforms
      module Merge
        ::Merge = Kiba::Extend::Transforms::Merge

        class ConstantValue
          def initialize(target:, value:)
            @target = target
            @value = value
          end

          def process(row)
            row[@target] = @value
            row
          end
        end
        
        # used when lookup may return an array of rows from which values should be merged
        #  into the target, AND THE TARGET IS MULTIVALUED
        class MultiRowLookup
          def initialize(fieldmap:, constantmap: {}, lookup:, keycolumn:,
                         exclusion_criteria: {}, selection_criteria: {}, delim: DELIM)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap #hash of constants to add for each merged-in row
            @lookup = lookup #lookuphash; should be created with csv_to_multi_hash
            @keycolumn = keycolumn #column in main table containing value expected to be lookup key
            @exclusion_criteria = exclusion_criteria #hash of constraints a row must NOT meet in order to be merged
            @selection_criteria = selection_criteria #hash of contraints a rom must meet in order to be merged
            @delim = delim
          end

          def process(row)
            id = row.fetch(@keycolumn)
            h = {}
            @fieldmap.each_key{ |k| h[k] = [] }
            @constantmap.each_key{ |k| h[k] = [] }

            merge_rows = @lookup.fetch(id, [])
            merge_rows = merge_rows.reject{ |mrow| exclude?(row, mrow) }
            if merge_rows.size > 0 && @selection_criteria.dig(:position) == 'first'
              merge_rows = [merge_rows.first]
            end

            merge_rows.each do |mrow|
              @fieldmap.each{ |target, source| h[target] << mrow.fetch(source, '') }
              @constantmap.each{ |target, value| h[target] << value }
            end

            chk = @fieldmap.map{ |target, source| h[target].size }.uniq.sort

            if chk[0] == 0
              h.each{ |target, arr| row[target] = nil }
            else
              h.each{ |target, arr| row[target] = arr.join(@delim) }
            end
            
            row
          end

          private

          def exclude?(row, mrow)
            bool = [false]
            @exclusion_criteria.each do |type, hash|
              case type
              when :field_equal
                bool << exclude_on_equality?(row, mrow, hash)
              end
            end
            bool.flatten.any? ? true : false
          end

          def exclude_on_equality?(row, mrow, hash)
            bool = []
            hash.each{ |rowfield, mergefield| row.fetch(rowfield) == mrow.fetch(mergefield) ? bool << true : bool << false }
            bool
          end
        end

        # used when lookup may return an array of rows from which values should be merged
        #  into the target, AND THE TARGET IS SINGLE VALUED
        class MultiRowLookupBLAH
          def initialize(fieldmap:, constantmap: {}, lookup:, keycolumn:, exclusion_criteria: {}, delim: DELIM)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap #hash of constants to add for each merged-in row
            @lookup = lookup #lookuphash; should be created with csv_to_multi_hash
            @keycolumn = keycolumn #column in main table containing value expected to be lookup key
            @exclusion_criteria = exclusion_criteria #hash of constraints a row must NOT meet in order to be merged
            @delim = delim
          end

          def process(row)
            id = row.fetch(@keycolumn)
            h = {}
            @fieldmap.each_key{ |k| h[k] = [] }
            @constantmap.each_key{ |k| h[k] = [] }
            
            @lookup.fetch(id, []).each do |mrow|
              unless exclude?(row, mrow)
                @fieldmap.each{ |target, source| h[target] << mrow.fetch(source, '') }
                @constantmap.each{ |target, value| h[target] << value }
              end
            end

            chk = @fieldmap.map{ |target, source| h[target].size }.uniq.sort

            if chk[0] == 0
              h.each{ |target, arr| row[target] = nil }
            else
              h.each{ |target, arr| row[target] = arr.join(@delim) }
            end
            
            row
          end

          private

          def exclude?(row, mrow)
            bool = [false]
            @exclusion_criteria.each do |type, hash|
              case type
              when :field_equal
                bool << exclude_on_equality?(row, mrow, hash)
              end
            end
            bool.flatten.any? ? true : false
          end

          def exclude_on_equality?(row, mrow, hash)
            bool = []
            hash.each{ |rowfield, mergefield| row.fetch(rowfield) == mrow.fetch(mergefield) ? bool << true : bool << false }
            bool
          end
        end

      end # module Merge
    end #module Transforms
  end #module Extend
end #module Kiba
