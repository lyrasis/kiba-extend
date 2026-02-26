# frozen_string_literal: true

module Kiba
  module Extend
    module JobTest
      module CsvJob
        # Checks that indicated value(s) is/are nil or empty strings
        class Blank
          include Testable

          # @overload initialize(config)
          # @param config [Hash] Other keys will be part of the config Hash, but
          #   are not required for this class' function
          # @option config [String] :path Path to job output
          # @option config [Symbol] :select_field Field whose value will be used
          #   to select row(s) to test
          # @option config [String] :select_value Value that will be matched
          #   (using ==) in :select_field to select test row(s)
          # @option config [Symbol] :test_field Field to be tested in selected
          #   row(s)
          # @option config [:first, :all] :select_qualifier Which of the
          #   selected rows to test
          def initialize(config, job_data = nil)
            initialization_logic(config)
          end

          # @return [String]
          def desc
            "When #{select_field} is #{select_value}, #{test_field} is blank"
          end

          private

          attr_reader :rows

          # @return [:success, String]
          def run
            @rows = job_data.select { |r| r[select_field] == select_value }

            testset = case select_qualifier
            when :all
              rows
            when :first
              [rows.first]
            else
              fail("Unknown `select_qualifier` value")
            end
            return :success if testset.all? { |row| row[test_field].blank? }

            testset.map do |row|
              if row[test_field].nil?
                "%NULLVALUE%"
              elsif row[test_field].empty?
                "%EMPTYSTRING%"
              else
                row[test_field]
              end
            end.join(" ||| ")
          end

          def key_conversions = {
            select_field: :to_sym,
            select_value: :to_s,
            test_field: :to_sym,
            select_qualifier: :to_sym
          }
        end

        def required_keys = key_conversions.keys
      end
    end
  end
end
