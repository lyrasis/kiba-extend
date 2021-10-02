# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Adds values to the end of fields or rows
      module Append
        ::Append = Kiba::Extend::Transforms::Append

        # Adds the given field(s) to the row with nil value if they do not already exist in row
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | z  |
        # |----|
        # | zz |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Append::NilFields, fields: %i[a b c z]
        # ```
        #
        # Results in:
        #
        # ```
        # | z  | a   | b   | c   |
        # |----+-----+-----+-----|
        # | zz | nil | nil | nil |
        # ```
        class NilFields
          # @param fields [Array<Symbol>, Symbol] field name or list of field names to add
          def initialize(fields:)
            @fields = [fields].flatten
          end

          # @private
          def process(row)
            @fields.each do |field|
              row[field] = nil unless row.key?(field)
            end
            row
          end
        end

        # Adds the given value to the end of value of the given field. Does not affect nil/empty field values
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # ```
        # | name  |
        # |-------|
        # | Weddy |
        # | nil   |
        # |       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Append::ToFieldValue, field: :name, value: ' (name)'
        # ```
        #
        # Results in:
        #
        # ```
        # | name         |
        # |--------------|
        # | Weddy (name) |
        # | nil          |
        # |              |
        # ```
        class ToFieldValue
          # @param field [Symbol] name of field to append to
          # @param value [String] value to append to existing field values
          def initialize(field:, value:)
            @field = field
            @value = value
          end

          # @private
          def process(row)
            fv = row.fetch(@field, nil)
            return row if fv.blank?

            row[@field] = "#{fv}#{@value}"
            row
          end
        end
      end
    end
  end
end
