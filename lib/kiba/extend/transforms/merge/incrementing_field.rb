# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # Merges numeric incrementing value into target field
        #
        # @note This transform runs in memory, so for very large
        #   sources, it may take a long time or fail.
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Merge::IncrementingField, target: :inc
        #   xform = Merge::IncrementingField.new(target: :inc)
        #
        #   input = [
        #     {foo: "a"},
        #     {foo: "b"},
        #     {foo: "c"},
        #     {foo: "d"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", inc: 1},
        #     {foo: "b", inc: 2},
        #     {foo: "c", inc: 3},
        #     {foo: "d", inc: 4}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With custom start_val and increment_size
        #   # Used in pipeline as:
        #   # transform Merge::IncrementingField, target: :inc,
        #   #   start_val: 10, increment_size: 5
        #   xform = Merge::IncrementingField.new(target: :inc,
        #     start_val: 10, increment_size: 5)
        #
        #   input = [
        #     {foo: "a"},
        #     {foo: "b"},
        #     {foo: "c"},
        #     {foo: "d"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", inc: 10},
        #     {foo: "b", inc: 15},
        #     {foo: "c", inc: 20},
        #     {foo: "d", inc: 25}
        #   ]
        #   expect(result).to eq(expected)
        class IncrementingField
          # @param target [Symbol] target field in which to enter incrementing
          #   value
          # @param start_val [Integer]
          # @param increment_size [Integer]
          def initialize(target:, start_val: 1, increment_size: 1)
            @target = target
            @counter = start_val
            @increment_size = increment_size
            @rows = []
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            rows << row
            nil
          end

          def close
            rows.each do |row|
              row[target] = counter
              @counter += increment_size
              yield row
            end
          end

          private

          attr_reader :target, :counter, :increment_size, :rows
        end
      end
    end
  end
end
