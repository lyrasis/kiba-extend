# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Count
        # rubocop:todo Layout/LineLength
        # Merges count of lookup rows to be merged into specified field. By default it retuns the count
        # rubocop:enable Layout/LineLength
        #   as a string, since many of the other transforms assume string values
        # @since 2.6.0
        class MatchingRowsInLookup
          # @param lookup [Hash] created with `csv_to_multihash`
          # rubocop:todo Layout/LineLength
          # @param keycolumn [Symbol] field in the source containing value to match on
          # rubocop:enable Layout/LineLength
          # @param targetfield [Symbol] field to put the result value in
          # rubocop:todo Layout/LineLength
          # @param conditions [Hash] See [https://github.com/lyrasis/kiba-extend/blob/e5a77d4622334cd4f021ba3c4d7bf59f010472b2/spec/kiba/extend/utils/lookup_spec.rb#L477](RowSelector spec)
          # rubocop:enable Layout/LineLength
          #    for examples on how to use
          # rubocop:todo Layout/LineLength
          # @param result_type [Symbol<:str, :int>] form in which to return the resulting values
          # rubocop:enable Layout/LineLength
          def initialize(lookup:, keycolumn:, targetfield:, conditions: {},
            result_type: :str)
            @lookup = lookup
            @keycolumn = keycolumn
            @target = targetfield
            @conditions = conditions
            @result_type = result_type
            @selector = Lookup::RowSelector.call(
              conditions: conditions
            )
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            id = row.fetch(keycolumn)
            matches = lookup.fetch(id, [])
            if matches.size.zero?
              row[target] = finalize(0)
            else
              merge_rows = selector.call(
                origrow: row,
                mergerows: matches
              )
              row[target] = finalize(merge_rows.size)
            end
            row
          end

          private

          attr_reader :lookup, :keycolumn, :target, :conditions, :result_type,
            :selector

          def finalize(int)
            return int.to_s if result_type == :str

            int
          end
        end
      end
    end
  end
end
