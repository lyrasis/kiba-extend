# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # rubocop:todo Layout/LineLength
        # Merge constant value into one or more fields, based on the values of other fields in the row
        # rubocop:enable Layout/LineLength
        #
        # ## Examples
        #
        # Used in job as:
        #
        # ```
        # condition = ->(row) do
        # rubocop:todo Layout/LineLength
        #   row[:note].is_a?(String) && row[:note].match?(/gift|donation/i) && row[:type] != 'obj'
        # rubocop:enable Layout/LineLength
        # end
        # transform Merge::ConstantValueConditional,
        #   fieldmap: { reason: 'gift', cost: '0' },
        #   condition: condition
        # ```
        #
        # With input:
        #
        # ```
        # {note: 'Gift', type: 'acq'},
        # {reason: 'donation', note: 'Was a donation', type: 'acq'},
        # {note: 'Was a donation', type: 'obj'},
        # rubocop:todo Layout/LineLength
        # {reason: 'purchase', cost: '100', note: 'Purchased from Someone', type: 'acq'},
        # rubocop:enable Layout/LineLength
        # {note: '', type: 'acq'},
        # {note: nil, type: 'acq'}
        # ```
        #
        # Results in:
        #
        # ```
        # {reason: 'gift', cost: '0', note: 'Gift', type: 'acq'},
        # {reason: 'gift', cost: '0', note: 'Was a donation', type: 'acq'},
        # {reason: nil, cost: nil, note: 'Was a donation', type: 'obj'},
        # rubocop:todo Layout/LineLength
        # {reason: 'purchase', cost: '100', note: 'Purchased from Someone', type: 'acq'},
        # rubocop:enable Layout/LineLength
        # {reason: nil, cost: nil, note: '', type: 'acq'},
        # {reason: nil, cost: nil, note: nil, type: 'acq'}
        # ```
        #
        # Note that:
        #
        # rubocop:todo Layout/LineLength
        # - `reason` and `cost` constants are merged into matching first row, though no `reason` or `cost` field existed in input
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # - existing `reason` value is overwritten in matching second row, and new `cost` field + value added
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # - nil `reason` and `cost` fields added to non-matching third row (on the principle of always emitting rows with
        # rubocop:enable Layout/LineLength
        #     the same fields, so as to be writable to CSV)
        # rubocop:todo Layout/LineLength
        # - existing `reason` and `cost` values in non-matching fourth row returned as-is
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # Also note that the `condition` lambda checks that the value of `note` is a String before calling `match?` on it.
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   Otherwise, the lambda will throw an error on the last row, wher the value of `note` is nil.
        # rubocop:enable Layout/LineLength
        #
        # Here's what that looks like:
        #
        # Used in job as:
        #
        # ```
        # condition = ->(row) do
        # rubocop:todo Layout/LineLength
        #   row[:note].is_a?(row[:note].match?(/gift|donation/i) && row[:type] != 'obj' }
        # rubocop:enable Layout/LineLength
        # end
        # transform Merge::ConstantValueConditional,
        #   fieldmap: { reason: 'gift', cost: '0' },
        #   condition: condition
        # ```
        #
        # Will cause:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # Kiba::Extend::Transforms::Merge::ConstantValueConditional::ConditionError: Condition lambda throws error with row: {:note=>nil, :type=>"acq"}
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        # from /Users/kristina/code/mig/kiba-extend/lib/kiba/extend/transforms/merge/constant_value_conditional.rb:77:in `rescue in condition_met?'
        # rubocop:enable Layout/LineLength
        # Caused by NoMethodError: undefined method `match?' for nil:NilClass
        # rubocop:todo Layout/LineLength
        #       let(:condition){ ->(row){ row[:note].match?(/gift|donation/i) && row[:type] != 'obj' } }
        # rubocop:enable Layout/LineLength
        #                                             ^^^^^^^
        # ```
        #
        # rubocop:todo Layout/LineLength
        # Finally, note that the `condition` lambda must return a true/false value, indicating whether the constant(s)
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   should be merged into the given row. If the lambda returns something else, it will throw an error:
        # rubocop:enable Layout/LineLength
        #
        # Used in job as:
        #
        # ```
        # condition = ->(row){ row[:note].length }
        # transform Merge::ConstantValueConditional,
        #   fieldmap: { reason: 'gift', cost: '0' },
        #   condition: condition
        # ```
        #
        # Will cause:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # Kiba::Extend::Transforms::Merge::ConstantValueConditional::NonBooleanConditionError: `condition` lambda must return true or false
        # rubocop:enable Layout/LineLength
        # ```
        class ConstantValueConditional
          class NonBooleanConditionError < Kiba::Extend::Error
            def initialize(msg = "`condition` lambda must return true or false")
              super
            end
          end

          class ConditionError < Kiba::Extend::Error
            def initialize(row)
              msg = "Condition lambda throws error with row: #{row.inspect}"
              super(msg)
            end
          end

          # @param fieldmap [Hash{Symbol => String}]
          # @param condition [Proc] A lambda Proc is expected.
          # rubocop:todo Layout/LineLength
          #   The lambda function should return true or false (i.e. whether the constant should be merged into the row).
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   This is purposefully named differently from the `conditions` parameter used on transforms that leverage
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          #   {Kiba::Extend::Utils::Lookup::RowSelectorByLambda} to select from multiple rows.
          # rubocop:enable Layout/LineLength
          def initialize(fieldmap:, condition:)
            @fieldmap = fieldmap
            @condition = condition
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            if condition_met?(row)
              @fieldmap.each { |target, value| row[target] = value }
            else
              @fieldmap.each { |target, _value|
                row[target] = row[target] ? row.fetch(target) : nil
              }
            end
            row
          end

          private

          attr_reader :fieldmap, :condition

          def condition_met?(row)
            begin
              result = condition.call(row)
            rescue
              fail(ConditionError.new(row))
            end

            return result if result == true || result == false

            fail(NonBooleanConditionError.new)
          end
        end
      end
    end
  end
end
