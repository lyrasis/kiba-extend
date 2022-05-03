# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
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
      end
    end
  end
end
