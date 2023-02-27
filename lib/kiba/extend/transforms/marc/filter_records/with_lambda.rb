# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        module FilterRecords
          # Select or reject MARC records based on whether the specified
          #   lambda returns true or not
          #
          # @example Keeping matches
          #   xform = Marc::FilterRecords::WithLambda.new(
          #     action: :keep,
          #     lambda: ->(rec){ rec.tags.any?('880') },
          #   )
          #   results = []
          #   MARC::Reader.new(marc_file).each{ |rec|
          #     xform.process(rec){ |result| results << result }
          #   }
          #   expect(results.length).to eq(2)
          # @example Rejecting matches
          #   xform = Marc::FilterRecords::WithLambda.new(
          #     action: :reject,
          #     lambda: ->(rec){ rec.tags.any?('880') },
          #   )
          #   results = []
          #   MARC::Reader.new(marc_file).each{ |rec|
          #     xform.process(rec){ |result| results << result }
          #   }
          #   expect(results.length).to eq(8)
          # @example Given non-Boolean-returning lambda
          #   xform = Marc::FilterRecords::WithLambda.new(
          #     action: :reject,
          #     lambda: ->(rec){ rec.tags.select{ |tag| tag == '880' } },
          #   )
          #   result = ->{xform.process(MARC::Reader.new(marc_file).first)}
          #   expect{ result.call }.to raise_error(
          #     Kiba::Extend::BooleanReturningLambdaError
          #   )
          class WithLambda
            include ActionArgumentable
            # @param action [:keep, :reject] taken if the lambda returns true
            # @param lambda [Proc] Lambda Proc with one argument (the incoming
            #   MARC record), that returns true or false
            def initialize(action:, lambda:)
              validate_action_argument(action)
              @action = action
              @lambda = lambda
              @lambda_validated = false
            end

            # @param record [MARC::Record] to check for ID match
            # @yield record MARC record, if it matches criteria
            # @yieldparam [MARC::Record] yielded MARC record, if any
            def process(record)
              validate_lambda(record) unless lambda_validated

              case action
              when :keep
                yield record if match?(record)
              when :reject
                yield record unless match?(record)
              end
              nil
            end

            private

            attr_reader :action, :lambda, :lambda_validated

            def match?(record)
              lambda.call(record)
            end

            def validate_lambda(record)
              returned = lambda.call(record)
              if [true, false].any?(returned)
                @lambda_validated = true
              else
                fail Kiba::Extend::BooleanReturningLambdaError
              end
            end
          end
        end
      end
    end
  end
end
