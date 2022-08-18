# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Compare
        # @since 2.7.1.62
        # Compares values in the given fields and puts `same` or `diff` in the given target field.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | id  | pid | zid |
        # |-----+-----+-----|
        # | a   | a   | a   |
        # | A   | a   | a   |
        # | a   |  a  |  a  |
        # |     | a   | a   |
        # | nil | a   | a   |
        # |     | nil |     |
        # ```
        #
        # The values in the third row are id = 'a ', pid = ' a', zid = ' a '.
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Compare::FieldValues, fields: %i[id pid zid], target: :comp
        # ```
        #
        # Results in:
        #
        # ```
        # | id  | pid | zid | comp |
        # |-----+-----+-----+------|
        # | a   | a   | a   | same |
        # | A   | a   | a   | same |
        # | a   |  a  |  a  | same |
        # |     | a   | a   | diff |
        # | nil | a   | a   | diff |
        # |     | nil |     | same |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Compare::FieldValues, fields: %i[id pid zid], target: :comp, downcase: false, strip: false
        # ```
        #
        # Results in:
        #
        # ```
        # | id  | pid | zid | comp |
        # |-----+-----+-----+------|
        # | a   | a   | a   | same |
        # | A   | a   | a   | diff |
        # | a   |  a  |  a  | diff |
        # |     | a   | a   | diff |
        # | nil | a   | a   | diff |
        # |     | nil |     | same |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Compare::FieldValues, fields: %i[id pid zid], target: :comp, ignore_blank: true
        # ```
        #
        # Results in:
        #
        # ```
        # | id  | pid | zid | comp |
        # |-----+-----+-----+------|
        # | a   | a   | a   | same |
        # | A   | a   | a   | same |
        # | a   |  a  |  a  | same |
        # |     | a   | a   | same |
        # | nil | a   | a   | same |
        # |     | nil |     | same |
        # ```
        #
        class FieldValues
          # @param fields [Array<Symbol>] names of fields whose values will be compared
          # @param target [Symbol] new field in which to record comparison result
          # @param downcase [Boolean] whether to downcase all values for comparison. `false` results in a case sensitive
          #   comparison. `true` results in a case insensitive comparison.
          # @param strip [Boolean] whether to remove leading/trailing spaces prior to comparison
          # @param ignore_blank [Boolean] `true` drops empty or nil values from the comparison
          def initialize(fields:, target:, downcase: true, strip: true, ignore_blank: false)
            @fields = [fields].flatten
            @target = target
            @strip = strip
            @downcase = downcase
            @ignore_blank = ignore_blank
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            row[@target] = 'diff'
            values = []
            @fields.each do |field|
              value = row.fetch(field, '').dup
              value = '' if value.nil?
              value = value.downcase if @downcase
              value = value.strip if @strip
              values << value
            end
            values.reject!(&:blank?) if @ignore_blank
            row[@target] = 'same' if values.uniq.length == 1 || values.empty?
            row
          end
        end
      end
    end
  end
end
