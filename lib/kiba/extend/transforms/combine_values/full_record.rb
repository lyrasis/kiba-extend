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
          include SepDeprecatable

          # @param target [Symbol] Field into which to write full record
          # @param sep [String] Will be deprecated in a future version. Do not
          #   use.
          # @param delim [String] Value used to separate individual field values
          #   in combined target field
          def initialize(target: :index, sep: nil, delim: nil)
            @target = target
            @delim = usedelim(
              sepval: sep,
              delimval: delim,
              calledby: self,
              default: " "
            )
            @fields = nil
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            set_fields(row) unless fields

            vals = fields.map { |field| row[field] }
              .reject(&:blank?)

            row[target] = if vals.empty?
                             nil
                           else
                             vals.join(delim)
                           end
            row
          end

          private

          attr_reader :target, :delim, :fields

          def set_fields(row)
            @fields = row.keys
          end
        end
      end
    end
  end
end
