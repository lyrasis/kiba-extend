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

        # How the conditions are applied
        #  :fields_empty
        #    ALL fields listed must be nil or empty
        #  :fields_populated
        #    ALL fields listed must be populated
        #  :fields_match_regexp
        #    Multiple match values may be given to test for a single field
        #    ALL fields listed must match at least one of its match values
        class ConstantValueConditional
          def initialize(fieldmap:, conditions: {}, sep: nil)
            @fieldmap = fieldmap
            @conditions = conditions
            @sep = sep
          end

          def process(row)
            if conditions_met?(row)
              @fieldmap.each{|target, value| row[target] = value }
            else
              @fieldmap.each{|target, value| row[target] = row.dig(target) ? row.fetch(target) : nil }
            end
            row
          end

          private

          def conditions_met?(row)
            chk = Lookup::RowSelector.new(
              origrow: row,
              mergerows: [],
              conditions: @conditions,
              sep: @sep
            ).result
            chk.empty? ? false : true
          end

        end
        
        class CountOfMatchingRows
          def initialize(lookup:, keycolumn:, targetfield:,
                         conditions: {}
                        )
            @lookup = lookup
            @keycolumn = keycolumn
            @target = targetfield
            @conditions = conditions
          end

          def process(row)
            id = row.fetch(@keycolumn)
            matches = @lookup.fetch(id, [])
            if matches.size == 0
              row[@target] = 0
            else
              merge_rows = Lookup::RowSelector.new(
                origrow: row,
                mergerows: @lookup.fetch(id, nil),
                conditions: @conditions
              ).result
              row[@target] = merge_rows.size
            end
            row
          end
        end

        class FieldGroupConstant
          def initialize(on_field:, target:, value:, sep:, placeholder:)
            @on_field = on_field
            @target = target
            @value = value
            @sep = sep
            @placeholder = placeholder
          end

          def process(row)
            field_val = row.fetch(@on_field, nil)
            if field_val.blank?
              row[@target] = @placeholder
              return row
            end

            merge_vals = []
            field_val.split(@sep, -1).each do |field_val|
              if field_val == @placeholder || field_val.blank?
                merge_vals << @placeholder
              else
                merge_vals << @value
              end
            end

            row[@target] = merge_vals.join(@sep)
            row
          end
        end
        
        # used when lookup may return an array of rows from which values should be merged
        #  into the target, AND THE TARGET IS MULTIVALUED
        class MultiRowLookup
          def initialize(fieldmap:, constantmap: {}, lookup:, keycolumn:,
                         conditions: {}, delim: DELIM)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap #hash of constants to add for each merged-in row
            @lookup = lookup #lookuphash; should be created with csv_to_multi_hash
            @keycolumn = keycolumn #column in main table containing value expected to be lookup key
            @conditions = conditions
            @delim = delim
          end

          def process(row)
            id = row.fetch(@keycolumn)
            fh = {}
            ch = {}
            @fieldmap.each_key{ |k| fh[k] = [] }
            @constantmap.each_key{ |k| ch[k] = [] }

            merge_rows = @lookup.fetch(id, [])

            if merge_rows.size > 0
              keep_rows = Lookup::RowSelector.new(
                origrow: row,
                mergerows: @lookup.fetch(id, []),
                conditions: @conditions,
                sep: @delim
              ).result
              
              keep_rows.each do |mrow|
                mergevals = []
                @fieldmap.each do |target, source|
                  val = mrow.fetch(source, nil)
                  result = val.blank? ? nil : val
                  fh[target] << result
                  mergevals << result
                end
                if mergevals.compact.empty?
                  @constantmap.each{ |target, value| ch[target] << nil }
                else
                  @constantmap.each{ |target, value| ch[target] << value }
                end
              end

              chk = @fieldmap.map{ |target, source| fh[target].compact.size }.uniq.sort

              if chk == [0]
                fh.each{ |target, arr| row[target] = nil }
                ch.each{ |target, arr| row[target] = nil }
              else
                fh.each{ |target, arr| row[target] = arr.join(@delim) }
                ch.each{ |target, arr| row[target] = arr.join(@delim) }
              end
            else
              @fieldmap.keys.each{ |f| row[f] = nil }
              @constantmap.keys.each{ |f| row[f] = nil }
            end
            row
          end
        end
      end # module Merge
    end #module Transforms
  end #module Extend
end #module Kiba
