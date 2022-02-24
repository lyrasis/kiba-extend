# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Prepend

        # Adds the specified value to the specified field
        #
        # If target field value is blank, it is left blank
        #
        # ## Examples
        #
        # Input table:
        #
        # ```
        # | name          |
        # |---------------|
        # | Weddy         |
        # | Kernel|Zipper |
        # | nil           |
        # |               |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Prepend::ToFieldValue, field: :name, value: 'aka: '
        # ```
        #
        # Results in:
        #
        # ```
        # | name               |
        # |--------------------|
        # | aka: Weddy         |
        # | aka: Kernel|Zipper |
        # | nil                |
        # |                    |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Prepend::ToFieldValue, field: :name, value: 'aka: ', mvdelim: '|'
        # ```
        #
        # Results in:
        #
        # ```
        # | name                    |
        # |-------------------------|
        # | aka: Weddy              |
        # | aka: Kernel|aka: Zipper |
        # | nil                     |
        # |                         |
        # ```
        #
        class ToFieldValue
          # @param field [Symbol] The field to prepend to
          # @param value [String] The value to be prepended
          # @param mvdelim [String] Character(s) on which to split multiple values in field before
          #   prepending. If empty string, behaves as a single value field
          def initialize(field:, value:, mvdelim: '')
            @field = field
            @value = value
            @mvdelim = mvdelim
          end

          # @private
          def process(row)
            fv = row.fetch(@field, nil)
            return row if fv.blank?

            fieldvals = @mvdelim.blank? ? [fv] : fv.split(@mvdelim)
            row[@field] = fieldvals.map { |v| "#{@value}#{v}" }.join(@mvdelim)
            row
          end
        end
      end
    end
  end
end
