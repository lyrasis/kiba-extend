# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      module CsvJob
        # Selects rows matching select field/value
        class Equal
          include Testable

          # @overload initialize(config)
          # @param config [Hash] Other keys will be part of the config Hash, but
          #   are not required for this class' function
          # @option config [String] :path Path to job output
          # @option config [Symbol] :select_field Field whose value will be used
          #   to select row to test
          # @option config [String] :select_value Value that will be matched
          #   (using ==) in :select_field to select test row
          # @option config [Symbol] :test_field Field in first row of test rows
          #   whose value will be tested
          # @option config [String] :expected Value expected in :test_field of
          #   first row of test rows
          def initialize(config, job_data = nil)
            initialization_logic(config)
          end

          # @return [String]
          def desc
            "When #{select_field} is #{select_value}, #{test_field} == "\
              "#{expected}"
          end

          private

          attr_reader :rows

          # @return [:success, String]
          def run
            @rows = job_data.select { |r| r[select_field] == select_value }
            val = if rows.empty?
              "no rows matching select criteria"
            else
              rows.first[test_field]
            end
            return :success if val == expected

            val
          end

          def required_keys = %i[select_field select_value test_field expected]
        end
      end
    end
  end
end
