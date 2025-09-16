# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # Delete a field value if the arbitrary Lambda passed in evaluates to
        #   true
        #
        # @example Without delim
        #   xform = Delete::FieldValueConditional.new(
        #     fields: %i[a b],
        #     lambda: ->(val, row) { row[:c] == val }
        #   )
        #
        #   input = [
        #     {a: nil, b: "", c: "c"},
        #     {a: "c", b: "b", c: "c"},
        #     {a: "a|c", b: "c", c: "c"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: nil, b: nil, c: "c"},
        #     {a: nil, b: "b", c: "c"},
        #     {a: "a|c", b: nil, c: "c"}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With delim
        #   xform = Delete::FieldValueConditional.new(
        #     fields: %i[a b],
        #     lambda: ->(val, row) { row[:c] == val },
        #     delim: "|"
        #   )
        #
        #   input = [
        #     {a: nil, b: "", c: "c"},
        #     {a: "c", b: "b", c: "c"},
        #     {a: "a|c", b: "c", c: "c"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: nil, b: nil, c: "c"},
        #     {a: nil, b: "b", c: "c"},
        #     {a: "a", b: nil, c: "c"}
        #   ]
        #   expect(result).to eq(expected)
        #
        class FieldValueConditional
          include BooleanLambdaParamable

          # @param fields [Array<Symbol>,Symbol] field(s) to delete from
          # @param lambda [Lambda] with one parameter for row to be passed in
          #   through. The Lambda must take `val` and `row` positional arguments
          #   and evaulate to/return `TrueClass` or `FalseClass`
          # @param delim [nil, String] if provided, turns on multivalue mode;
          #   each whole field value is split into values, each of which is
          #   sent as `val` to the lambda
          def initialize(fields:, lambda:, delim: nil)
            @fields = [fields].flatten
            @lambda = lambda
            @multival = delim ? true : false
            @delim = delim || Kiba::Extend.delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          # @raise [Kiba::Extend::BooleanReturningLambdaError] if given lambda
          #   does not evaluate to `TrueClass` or `FalseClass` using
          #   the first row of data passed to the `process` method
          def process(row)
            test_lambda(["foo", row]) unless lambda_tested

            fields.each { |field| row[field] = delete_from_field(row, field) }
            row
          end

          private

          attr_reader :fields, :lambda, :multival, :delim

          def delete_from_field(row, field)
            val = row[field]
            return if val.blank?
            return do_deletes([val], row, field) unless multival

            do_deletes(val.split(delim), row, field)
          end

          # @param vals [Array<String>]
          def do_deletes(vals, row, field)
            result = vals.map { |val| lambda.call(val, row) ? nil : val }
              .compact
            return nil if result.empty?

            result.join(delim)
          end
        end
      end
    end
  end
end
