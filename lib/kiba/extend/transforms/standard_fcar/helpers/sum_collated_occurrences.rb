# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module StandardFcar
        module Helpers
          # Splits on delim, converts to numbers, replaces with sum of numbers
          #
          # If any value has anything other than digits, returns original value
          #   and puts a warning.
          #
          # @example With defaults
          #   # Used in pipeline as:
          #   # transform StandardFcar::Helpers::SumCollatedOccurrences
          #
          #   xform = StandardFcar::Helpers::SumCollatedOccurrences.new
          #   input = [
          #     {occurrences: "5"},
          #     {occurrences: "5////5"},
          #     {occurrences: "alpha"}
          #   ]
          #   result = input.map{ |row| xform.process(row) }
          #   expected = [
          #     {occurrences: 5},
          #     {occurrences: 10},
          #     {occurrences: "alpha"}
          #   ]
          #   expect(result).to eq(expected)
          class SumCollatedOccurrences
            include Kiba::Extend::Transforms::SingleWarnable

            # @param field [Symbol]
            # @param delim [String]
            def initialize(field: :occurrences, delim: "////")
              @field = field
              @delim = delim
              setup_single_warning
            end

            def process(row)
              fieldval = row[field]
              return row if fieldval.blank?

              vals = fieldval.split(delim)

              if valid?(vals)
                row[field] = vals.map(&:to_i).sum
              else
                add_single_warning(
                  "#{self.class.name}: Non-numeric value(s) in #{field}"
                )
              end

              row
            end

            private

            attr_reader :field, :delim

            def valid?(vals)
              vals.map { |val| val.match?(/^\d+$/) }.all?
            end
          end
        end
      end
    end
  end
end
