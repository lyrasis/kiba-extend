# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module FilterRows
        # @since 2.9.0
        #
        # Keep or reject rows based on whether the arbitrary Lambda passed in
        #   evaluates to true/false
        #
        # @example Keeping rows with nil values
        #   # Used in pipeline as:
        #   # transform FilterRows::WithLambda,
        #   #   action: :keep,
        #   #   lambda: ->(row) { row.values.any?(nil) }
        #   xform = FilterRows::WithLambda.new(
        #     action: :keep,
        #     lambda: ->(row) { row.values.any?(nil) }
        #   )
        #
        #   input = [
        #     {a: "a", b: "b", c: "c"},
        #     {a: "a", b: "b", c: ""},
        #     {a: "", b: nil, c: "c"},
        #     {a: "", b: "b", c: "c"},
        #     {a: "", b: nil, c: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: "", b: nil, c: "c"},
        #     {a: "", b: nil, c: nil}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Rejecting rows with nil values
        #   # Used in pipeline as:
        #   # transform FilterRows::WithLambda,
        #   #   action: :reject,
        #   #   lambda: ->(row) { row.values.any?(nil) }
        #   xform = FilterRows::WithLambda.new(
        #     action: :reject,
        #     lambda: ->(row) { row.values.any?(nil) }
        #   )
        #
        #   input = [
        #     {a: "a", b: "b", c: "c"},
        #     {a: "a", b: "b", c: ""},
        #     {a: "", b: nil, c: "c"},
        #     {a: "", b: "b", c: "c"},
        #     {a: "", b: nil, c: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: "a", b: "b", c: "c"},
        #     {a: "a", b: "b", c: ""},
        #     {a: "", b: "b", c: "c"}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example When Lambda does not evaluate to true/false
        #   row = {a: "a", b: "b", c: "c"}
        #   expect{
        #     FilterRows::WithLambda.new(action: :keep, lambda: ->(row) { [] })
        #     .process(row)
        #   }.to raise_error(Kiba::Extend::BooleanReturningLambdaError)
        # @raise [Kiba::Extend::BooleanReturningLambdaError] if given lambda
        #   does not evaluate to `TrueClass` or `FalseClass` using
        #   the first row of data passed to the `process` method
        class WithLambda
          include ActionArgumentable
          include BooleanLambdaParamable

          # @param action [:keep, :reject] what to do with row matching criteria
          # @param lambda [Lambda] with one parameter for row to be passed in
          #   through. The Lambda must evaulate
          #   to/return `TrueClass` or `FalseClass`
          def initialize(action:, lambda:)
            validate_action_argument(action)
            @action = action
            @lambda = lambda
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            test_lambda(row) unless lambda_tested

            case action
            when :keep
              row if lambda.call(row)
            when :reject
              row unless lambda.call(row)
            end
          end

          private

          attr_reader :action, :lambda
        end
      end
    end
  end
end
