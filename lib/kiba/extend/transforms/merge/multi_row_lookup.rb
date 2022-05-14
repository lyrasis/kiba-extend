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

          # @param fieldmap [Hash{Symbol => Symbol}] key = field in source row to merge lookup data into; 
          #   value = field from lookup table whose value maps into target field
          # @param lookup [Hash] created by Utils::LookupHash. If you have registered a job as a lookup,
          #   kiba-extend takes care of creating this for you.
          # @param keycolumn [Symbol] the field in the source data that is expected to match against the
          #   keycolumn used to create the lookup hash. I.e. the field you will be matching on in the
          #   **source** data
          # @param constantmap [Hash{Symbol => String}] constant data to map into any rows that get data
          #   merged in from lookup table. Key = the field in source row to merge the constant value into;
          #   value = the constant value to merge in
          # @param conditions [Hash, Lambda] logic used to select which lookup rows data should be merged
          #   in from. The Hash option is pretty horrible and not at all documented. See the
          #   [Lookup::RowSelectorByHash spec](https://github.com/lyrasis/kiba-extend/blob/main/spec/kiba/extend/utils/lookup/row_selector_by_hash_spec.rb)
          #   for some examples. The Lambda option is probably more straightforward and flexible. See
          #   {Kiba::Extend::Utils::Lookup::RowSelectorByLambda} for examples.
          # @param multikey [Boolean] whether the source keycolumn should be treated as multivalued. I.e.
          #   it will be split on the given `delim`, and each resulting element of the split array will
          #   be used to retrieve rows from the lookup table to merge into this row
          # @param delim [String] on which to split multikey values, and to use in joining merged data in each
          #   field if multiple lookup rows are retrieved
          # @param null_placeholder [String] such as `%NULLVALUE%` to merge in place of an empty/nil value.
          #   Note that this is only used if some data is being merged into the row. That is, if no lookup
          #   rows are found to merge in, all the target columns are left blank. This is useful mainly for
          #   situtations where you are merging in multiple fields which can each have multiple values, and
          #   you need to make sure groups of fields have the same number of values in them
          # @param sorter [nil, Lookup::RowSorter] handles sorting of lookup rows to control the order they
          #   are merged in. Without specifying a sorter, the lookup data is merged in the order it appears
          #   in the lookup table. So, if you ensure your lookup data source is sorted as desired prior to
          #   using it in a lookup, you may not need a sorter.
          # @note Interaction of specifying a `sorter` and `multikey: true` may be unexpected. 
          def initialize(fieldmap:, lookup:, keycolumn:, constantmap: {},
                         conditions: {}, multikey: false, delim: DELIM, null_placeholder: nil,
                         sorter: nil)
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
            @sort_dir = sort_dir
            @selector = Lookup::RowSelector.call(
              conditions: conditions,
              sep: delim
            )
            @sorter = sorter
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

          attr_reader :fieldmap, :constantmap, :lookup, :keycolumn, :multikey, :conditions,
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
