# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete

        # Deletes field(s) passed in `fields` parameter.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | a | b | c |
        # |---+---+---|
        # | 1 | 2 | 3 |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::Fields, fields: %i[a c]
        # ```
        #
        # Results in:
        #
        # ```
        # | b |
        # |---|
        # | 2 |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::Fields, fields: :b
        # ```
        #
        # Results in:
        #
        # ```
        # | a | c |
        # |---+---|
        # | 1 | 3 |
        # ```
        #
        class Fields
          # @param fields [Array<Symbol>,Symbol] field(s) to delete from
          def initialize(fields:)
            @fields = [fields].flatten
          end

          # @private
          def process(row)
            fields.each { |name| row.delete(name) }
            row
          end

          private

          attr_reader :fields
        end
      end
    end
  end
end
