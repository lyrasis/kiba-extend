# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # @since 2.8.0.85
        # Keep or reject rows based on whether the arbitrary Lambda passed in evaluates to true/false
        #
        # ## Examples
        #
        # Source data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' },
        # {a: 'a', b: 'b', c: '' },
        # {a: '', b: nil, c: 'c' },
        # {a: '', b: 'b', c: 'c' },
        # {a: '', b: nil, c: nil },
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # logic = ->(row){ row.values.any?(nil) }
        # transform FilterRows::WithLambda, action: :keep, lambda: logic
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: '', b: nil, c: 'c' },
        # {a: '', b: nil, c: nil }
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # whatever = ->(x) do
        #   x.values.any?(nil)
        # end
        # transform FilterRows::WithLambda, action: :keep, lambda: whatever
        # ```
        #
        # Resulting data:
        #
        # ```
        # {a: 'a', b: 'b', c: 'c' },
        # {a: 'a', b: 'b', c: '' },
        # {a: '', b: 'b', c: 'c' },
        # ```
        #
        # The following will raise a NonBooleanLambdaError because `logic` returns an Array, rather than
        #   `TrueClass` or `FalseClass`:
        #
        # ```
        # logic = ->(row){ row.values.select{ |val| val.nil? } }
        # transform FilterRows::WithLambda, action: :keep, lambda: logic
        # ```
        #
        # @raise [NonBooleanLambdaError] if given lambda does not evaluate to `TrueClass` or `FalseClass` using
        #   the first row of data passed to the `process` method
        class WithLambda
          class NonBooleanLambdaError < Kiba::Extend::Error; end

          # @param action [:keep, :reject] what to do with row matching criteria
          # @param lambda [Lambda] with one parameter for row to be passed in through. The Lambda must evaulate
          #   to/return `TrueClass` or `FalseClass`
          def initialize(action:, lambda:)
            @action = action
            @lambda = lambda
            @lambda_tested = false
          end

          # @private
          def process(row)
            test_lambda(row) unless lambda_tested
            
            case action
            when :keep
              return row if lambda.call(row)
            when :reject
              return row unless lambda.call(row)
            end
          end

          private

          attr_reader :action, :lambda, :lambda_tested

          def test_lambda(row)
            result = lambda.call(row)
            fail(NonBooleanLambdaError) unless result.is_a?(TrueClass) || result.is_a?(FalseClass)
            
            @lambda_tested = true
          end
        end
      end
    end
  end
end
