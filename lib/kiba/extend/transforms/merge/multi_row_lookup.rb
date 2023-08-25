# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # rubocop:todo Layout/LineLength
        # Merge one or more rows from a {Kiba::Extend::Utils::LookupHash} into source data, matching on
        # rubocop:enable Layout/LineLength
        #   `keycolumn` values
        class MultiRowLookup
          # @since 2.8.0
          class LookupTypeError < Kiba::Extend::Error
            def initialize(lookup)
              @lookup = lookup
              super("Lookup value `#{lookup} (#{lookup.class})` must be a Hash")
            end

            private

            attr_reader :lookup
          end

          class EmptyFieldmap < Kiba::Extend::Error; end

          # rubocop:todo Layout/LineLength
          # @param fieldmap [Hash{Symbol => Symbol}] key = field in source row to merge lookup data into;
          # rubocop:enable Layout/LineLength
          #   value = field from lookup table whose value maps into target field
          # rubocop:todo Layout/LineLength
          # @param lookup [Hash] created by Utils::LookupHash. If you have registered a job as a lookup,
          # rubocop:enable Layout/LineLength
          #   kiba-extend takes care of creating this for you.
          # rubocop:todo Layout/LineLength
          # @param keycolumn [Symbol] the field in the source data that is expected to match against the
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   keycolumn used to create the lookup hash. I.e. the field you will be matching on in the
          # rubocop:enable Layout/LineLength
          #   **source** data
          # rubocop:todo Layout/LineLength
          # @param constantmap [Hash{Symbol => String}] constant data to map into any rows that get data
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   merged in from lookup table. Key = the field in source row to merge the constant value into;
          # rubocop:enable Layout/LineLength
          #   value = the constant value to merge in
          # rubocop:todo Layout/LineLength
          # @param conditions [Hash, Lambda] logic used to select which lookup rows data should be merged
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   in from. The Hash option is pretty horrible and not at all documented. See the
          # rubocop:enable Layout/LineLength
          #   [Lookup::RowSelectorByHash spec](https://github.com/lyrasis/kiba-extend/blob/main/spec/kiba/extend/utils/lookup/row_selector_by_hash_spec.rb)
          # rubocop:todo Layout/LineLength
          #   for some examples. The Lambda option is probably more straightforward and flexible. See
          # rubocop:enable Layout/LineLength
          #   {Kiba::Extend::Utils::Lookup::RowSelectorByLambda} for examples.
          # rubocop:todo Layout/LineLength
          # @param multikey [Boolean] whether the source keycolumn should be treated as multivalued. I.e.
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   it will be split on the given `delim`, and each resulting element of the split array will
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   be used to retrieve rows from the lookup table to merge into this row
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param delim [String] on which to split multikey values, and to use in joining merged data in each
          # rubocop:enable Layout/LineLength
          #   field if multiple lookup rows are retrieved
          # rubocop:todo Layout/LineLength
          # @param null_placeholder [String] such as `%NULLVALUE%` to merge in place of an empty/nil value.
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   Note that this is only used if some data is being merged into the row. That is, if no lookup
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   rows are found to merge in, all the target columns are left blank. This is useful mainly for
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   situtations where you are merging in multiple fields which can each have multiple values, and
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   you need to make sure groups of fields have the same number of values in them
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param sorter [nil, Kiba::Extend::Utils::Lookup::RowSorter] handles sorting of lookup rows to control the order they
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   are merged in. Without specifying a sorter, the lookup data is merged in the order it appears
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   in the lookup table. So, if you ensure your lookup data source is sorted as desired prior to
          # rubocop:enable Layout/LineLength
          #   using it in a lookup, you may not need a sorter.
          # rubocop:todo Layout/LineLength
          # @note Interaction of specifying a `sorter` and `multikey: true` may be unexpected.
          # rubocop:enable Layout/LineLength
          def initialize(fieldmap:, lookup:, keycolumn:, constantmap: {},
            # rubocop:todo Layout/LineLength
            conditions: {}, multikey: false, delim: Kiba::Extend.delim, null_placeholder: nil,
            # rubocop:enable Layout/LineLength
            sorter: nil)
            # rubocop:todo Layout/LineLength
            @fieldmap = fieldmap # hash of looked-up values to merge in for each merged-in row
            # rubocop:enable Layout/LineLength
            fail EmptyFieldmap if fieldmap.empty?

            # rubocop:todo Layout/LineLength
            @constantmap = constantmap # hash of constants to add for each merged-in row
            # rubocop:enable Layout/LineLength
            # rubocop:todo Layout/LineLength
            @lookup = lookup # lookuphash; should be created with csv_to_multi_hash
            # rubocop:enable Layout/LineLength
            fail LookupTypeError.new(lookup) unless lookup.is_a?(Hash)

            # rubocop:todo Layout/LineLength
            @keycolumn = keycolumn # column in main table containing value expected to be lookup key
            # rubocop:enable Layout/LineLength
            @multikey = multikey # should the key be treated as multivalued
            @conditions = conditions
            @delim = delim
            @null_placeholder = null_placeholder
            @sort_on = sort_on
            @sort_dir = sort_dir
            @selector = Lookup::RowSelector.call(
              conditions: conditions,
              sep: delim
            )
            @sorter = sorter
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            field_data = Kiba::Extend::Utils::Fieldset.new(
              fields: fieldmap.values,
              null_placeholder: null_placeholder
            )

            id_data = row.fetch(keycolumn, "")
            id_data = id_data.nil? ? "" : id_data
            ids = multikey ? id_data.split(delim) : [id_data]

            ids.each do |id|
              rtm = rows_to_merge(id, row)
              field_data.populate(rtm)
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

          # rubocop:todo Layout/LineLength
          attr_reader :fieldmap, :constantmap, :lookup, :keycolumn, :multikey, :conditions,
            # rubocop:enable Layout/LineLength
            :delim, :null_placeholder, :sort_on, :sort_dir, :selector, :sorter

          def target_field(field)
            target = fieldmap.key(field)
            return target unless target.nil?

            field
          end

          def rows_to_merge(id, sourcerow)
            matches = lookup.fetch(id, [])
            return matches if matches.empty?

            results = selector.call(origrow: sourcerow, mergerows: matches)
            sort(results)
          end

          def sort(results)
            return results unless sorter
            return results if results.length < 2

            sorter.call(results)
          end
        end
      end
    end
  end
end
