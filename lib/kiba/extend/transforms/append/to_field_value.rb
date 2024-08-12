# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Append
        # Adds the given value to the end of value of the given field. Does not
        #   affect nil/empty field values
        #
        # @example Treated as single value (default)
        #   # Used in pipeline as:
        #   # transform Append::ToFieldValue, field: :name, value: " (name)"
        #
        #   xform = Append::ToFieldValue.new(field: :name, value: " (name)")
        #   input = [
        #       {name: "Weddy"},
        #       {name: "Kernel|Zipper"},
        #       {name: nil},
        #       {name: ""}
        #     ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #       {name: "Weddy (name)"},
        #       {name: "Kernel|Zipper (name)"},
        #       {name: nil},
        #       {name: ""}
        #     ]
        #   expect(result).to eq(expected)
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
