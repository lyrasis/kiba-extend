# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Mixin module for transform classes that require a Lambda parameter
      #   that must return TrueClass or FalseClass
      #
      # ## Testing
      #
      # This mixin's funtionality is tested in Marc::FilterRecords::WithLambda
      #   and FilterRows::WithLambda. It is not imperative to test in in every
      #   additional transform class where it may be used.
      #
      # ## Usage
      #
      # In class definition:
      #
      # ~~~
      # include BooleanLambdaParamable
      # ~~~
      #
      # Any transform classes mixing in this module must have a `@lambda`
      #   instance variable on which is also set an attr_reader (private
      #   or public is ok)
      #
      # Add the following line to the top of the `process` method:
      #
      # ~~~
      #  test_lambda(row) unless lambda_tested
      # ~~~
      module BooleanLambdaParamable
        ::BooleanLambdaParamable =
          Kiba::Extend::Transforms::BooleanLambdaParamable

        def self.included(mod)
          mod.instance_variable_set(:@lambda_tested, false)
        end

        def lambda_tested = @lambda_tested

        def test_lambda(row)
          result = lambda.call(row)
          unless result.is_a?(TrueClass) || result.is_a?(FalseClass)
            fail(Kiba::Extend::BooleanReturningLambdaError)
          end

          @lambda_tested = true
        end
      end
    end
  end
end
