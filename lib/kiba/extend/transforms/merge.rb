# frozen_string_literal: true

require_relative '../utils/fieldset'

module Kiba
  module Extend
    module Transforms
      # Transformations that add data from outside the data source
      #
      # Some other groups of transforms add specific kinds of external data:
      # @see Count
      module Merge
        ::Merge = Kiba::Extend::Transforms::Merge

        # @deprecated Use {Count::MatchingRowsInLookup} instead.
        CountOfMatchingRows = Count::MatchingRowsInLookup
        
        # @deprecated Use {Compare::FieldValues} instead.
        class CompareFieldsFlag
          def initialize(...)
            warn('DEPRECATED TRANSFORM. Use Compare::FieldValues instead')
            @xform = Compare::FieldValues.new(...)
          end

          # @private
          def process(row)
            xform.process(row)
          end

          private
          
          attr_reader :xform
        end

        class ConstantValue
          def initialize(target:, value:)
            @target = target
            @value = value
          end

          # @private
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

          # @private
          def process(row)
            if conditions_met?(row)
              @fieldmap.each { |target, value| row[target] = value }
            else
              @fieldmap.each { |target, _value| row[target] = row[target] ? row.fetch(target) : nil }
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

        # Adds a specified value to new target field for every value found in `on_field`
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | name                 |
        # |----------------------|
        # | Weddy                |
        # | NULL                 |
        # |                      |
        # | nil                  |
        # | Earlybird;Divebomber |
        # | ;Niblet              |
        # | Hunter;              |
        # | NULL;Earhart         |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Merge::MultivalueConstant, on_field: :name, target: :species, value: 'guinea fowl', sep: ';',
        #    placeholder: 'NULL'
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | species                 |
        # |----------------------+-------------------------|
        # | Weddy                | guinea fowl             |
        # | NULL                 | NULL                    |
        # |                      | NULL                    |
        # | nil                  | NULL                    |
        # | Earlybird;Divebomber | guinea fowl;guinea fowl |
        # | ;Niblet              | NULL;guinea fowl        |
        # | Hunter;              | guinea fowl;NULL        |
        # | NULL;Earhart         | NULL;guinea fowl        |
        # ```
        class MultivalueConstant
          # @param on_field [Symbol] field the new field's values will be based on
          # @param target [Symbol] name of new field
          # @param value [String] value to add to `target` for each existing value in `on_field`
          # @param sep [String] multivalue separator
          # @param placeholder [String] value to add to `target` for empty/nil values in `on_field`
          def initialize(on_field:, target:, value:, sep:, placeholder:)
            @on_field = on_field
            @target = target
            @value = value
            @sep = sep
            @placeholder = placeholder
          end

          # @private
          def process(row)
            field_val = row.fetch(@on_field, nil)
            if field_val.blank?
              row[@target] = @placeholder
              return row
            end

            merge_vals = []
            field_val.split(@sep, -1).each do |field_val|
              merge_vals << if field_val == @placeholder || field_val.blank?
                              @placeholder
                            else
                              @value
                            end
            end

            row[@target] = merge_vals.join(@sep)
            row
          end
        end

        # used when lookup may return an array of rows from which values should be merged
        #  into the target, AND THE TARGET IS MULTIVALUED
        class MultiRowLookup
          def initialize(fieldmap:, lookup:, keycolumn:, constantmap: {},
                         conditions: {}, multikey: false, delim: DELIM)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap # hash of constants to add for each merged-in row
            @lookup = lookup # lookuphash; should be created with csv_to_multi_hash
            @keycolumn = keycolumn # column in main table containing value expected to be lookup key
            @multikey = multikey # should the key be treated as multivalued
            @conditions = conditions
            @delim = delim
          end

          # @private
          def process(row)
            field_data = Kiba::Extend::Utils::Fieldset.new(@fieldmap.values)

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
      end
    end
  end
end
