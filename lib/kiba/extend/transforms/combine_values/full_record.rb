# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        # Concatenates values of all fields in each record together into the
        #   target field, using the given string as value separator in the
        #   combined value
        #
        # # Example
        #
        # Input table:
        #
        # ```
        # | name   | sex | source  |
        # |--------+-----+---------|
        # | Weddy  | m   | adopted |
        # | Niblet | f   | hatched |
        # | Keet   | nil | hatched |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform CombineValues::FullRecord, target: :index
        # ```
        #
        # Results in:
        #
        # ```
        # | name   | sex | source  | index            |
        # |--------+-----+---------+------------------|
        # | Weddy  | m   | adopted | Weddy m adopted  |
        # | Niblet | f   | hatched | Niblet f hatched |
        # | Keet   | nil | hatched | Keet hatched     |
        # ```
        class FullRecord
          # @param target [Symbol] Field into which to write full record
          # @param sep [String] Value used to separate individual field values
          #   in combined target field
          def initialize(target:, sep: ' ')
            @target = target
            @sep = sep
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            vals = row.keys.map { |k| row.fetch(k, nil) }
            vals = vals.compact
            row[@target] = if vals.empty?
                             nil
                           else
                             vals.join(@sep)
                           end
            row
          end
        end
      end
    end
  end
end
