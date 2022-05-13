# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # used when lookup may return an array of rows from which values should be merged
        #  into the target, AND THE TARGET IS MULTIVALUED
        class MultiRowLookup
          class LookupTypeError < Kiba::Extend::Error
            def initialize(lookup)
              @lookup = lookup
              super("Lookup value `#{lookup} (#{lookup.class})` must be a Hash")
            end

            private

            attr_reader :lookup
          end
          
          def initialize(fieldmap:, lookup:, keycolumn:, constantmap: {},
                         conditions: {}, multikey: false, delim: DELIM, null_placeholder: nil,
                         sort_on: nil)
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            @constantmap = constantmap # hash of constants to add for each merged-in row
            @lookup = lookup # lookuphash; should be created with csv_to_multi_hash
            fail LookupTypeError.new(lookup) unless lookup.is_a?(Hash)
            
            @keycolumn = keycolumn # column in main table containing value expected to be lookup key
            @multikey = multikey # should the key be treated as multivalued
            @conditions = conditions
            @delim = delim
            @null_placeholder = null_placeholder
            @sort_on = sort_on
            @selector = Lookup::RowSelector.call(
              conditions: conditions,
              sep: delim
            )
          end

          # @private
          def process(row)
            field_data = Kiba::Extend::Utils::Fieldset.new(
              fields: fieldmap.values,
              null_placeholder: null_placeholder
            )

            id_data = row.fetch(keycolumn, '')
            id_data = id_data.nil? ? '' : id_data
            ids = multikey ? id_data.split(delim) : [id_data]

            ids.each do |id|
              field_data.populate(rows_to_merge(id, row))
            end

            constantmap.each do |field, value|
              field_data.add_constant_values(field, value)
            end

            field_data.join_values(delim)

            field_data.hash.each do |field, value|
              row[target_field(field)] = value.blank? ? nil : value
            end

            row
          end

          private

          attr_reader :fieldmap, :constantmap, :lookup, :keycolumn, :multikey, :conditions,
            :delim, :null_placeholder, :sort_on, :selector

          def target_field(field)
            target = fieldmap.key(field)
            return target unless target.nil?

            field
          end

          def rows_to_merge(id, sourcerow)
            matches = lookup.fetch(id, [])
            return matches if matches.empty?

            selector.call(origrow: sourcerow, mergerows: matches)
          end
        end
      end
    end
  end
end
