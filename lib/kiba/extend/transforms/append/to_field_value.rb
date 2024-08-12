# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Append
        # # Examples
        #
        # Input table:
        #
        # ~~~
        # | name  |
        # |-------|
        # | Weddy |
        # | nil   |
        # |       |
        # ~~~
        #
        # Used in pipeline as:
        #
        # ~~~
        #  transform Append::ToFieldValue, field: :name, value: ' (name)'
        # ~~~
        #
        # Results in:
        #
        # ~~~
        # | name         |
        # |--------------|
        # | Weddy (name) |
        # | nil          |
        # |              |
        # ~~~
        class ToFieldValue
          # @param field [Symbol] name of field to append to
          # @param value [String] value to append to existing field values
          def initialize(field:, value:)
            @field = field
            @value = value
          end

          # @param row [Hash{ Symbol => String, nil }]
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
