# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Count
        # Merges count of lookup rows to be merged into specified field
        class MatchingRowsInLookup
          def initialize(lookup:, keycolumn:, targetfield:, conditions: {})
            @lookup = lookup
            @keycolumn = keycolumn
            @target = targetfield
            @conditions = conditions
          end

          # @private
          def process(row)
            id = row.fetch(@keycolumn)
            matches = @lookup.fetch(id, [])
            if matches.size.zero?
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
      end
    end
  end
end
