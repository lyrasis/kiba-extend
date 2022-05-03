# frozen_string_literal: true

#require_relative '../utils/fieldset'

module Kiba
  module Extend
    module Transforms
      module Merge
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
