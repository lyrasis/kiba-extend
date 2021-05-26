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

        class MultivalueConstant
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
                         conditions: {}, multikey: false, delim: DELIM)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap # hash of constants to add for each merged-in row
            @lookup = lookup # lookuphash; should be created with csv_to_multi_hash
            @keycolumn = keycolumn # column in main table containing value expected to be lookup key
            @multikey = multikey # should the key be treated as multivalued
            @conditions = conditions
            @delim = delim
          end

          def process(row)
            field_data = Kiba::Extend::Fieldset.new(@fieldmap.values)

            id_data = row.fetch(@keycolumn, '')
            id_data = id_data.nil? ? '' : id_data
            ids = @multikey ? id_data.split(@delim) : [id_data]


            ids.each do |id|
              field_data.populate(rows_to_merge(id, row))
            end

            @constantmap.each do |field, value|
              field_data.add_constant_values(field, value)
            end

            field_data.join_values(@delim)

            field_data.hash.each do |field, value|
              row[target_field(field)] = value.blank? ? nil : value
            end
            
            row
          end

          private

          def target_field(field)
            target = @fieldmap.key(field)
            return target unless target.nil?

            field
          end

          def rows_to_merge(id, sourcerow)
            matches = @lookup.fetch(id, [])
            return matches if matches.empty?

            Lookup::RowSelector.new(
              origrow: sourcerow,
              mergerows: @lookup.fetch(id, []),
              conditions: @conditions,
              sep: @delim
            ).result
          end
        end
      end # module Merge
    end #module Transforms
  end #module Extend
end #module Kiba
