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
        # transform Prepend::ToFieldValue, field: :name, value: 'aka: ', multival: true, delim: '|'
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
          # @note `mvdelim` argument is deprecated and replaced by `multival` and `delim`
          # @param field [Symbol] The field to prepend to
          # @param value [String] The value to be prepended
          # @param multival [Boolean] Whether prepend to multiple values
          # @param delim [String] for splitting value if `multival`
          def initialize(field:, value:, multival: false, delim: Kiba::Extend.delim)
            @field = field
            @value = value
            @multival = multival
            @delim = delim
          end

          # @private
          def process(row)
            fieldval = row.fetch(field, nil)
            return row if fieldval.blank?

            fieldvals = multival ? fieldval.split(delim) : [fieldval]
            row[field] = fieldvals.map { |fieldval| "#{value}#{fieldval}" }.join(delim)
            row
          end

          private

          attr_reader :field, :value, :multival, :delim
        end
      end
    end
  end
end
