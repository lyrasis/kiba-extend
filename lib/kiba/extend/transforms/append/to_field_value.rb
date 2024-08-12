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
        #
        # @example Treated as multivalue
        #   # Used in pipeline as:
        #   # transform Append::ToFieldValue,
        #   #   field: :name,
        #   #   value: " (name)",
        #   #   delim: "|"
        #
        #   xform = Append::ToFieldValue.new(field: :name, value: " (name)",
        #     delim: "|")
        #   input = [
        #       {name: "Weddy"},
        #       {name: "Kernel|Zipper"},
        #       {name: nil},
        #       {name: ""}
        #     ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #       {name: "Weddy (name)"},
        #       {name: "Kernel (name)|Zipper (name)"},
        #       {name: nil},
        #       {name: ""}
        #     ]
        #   expect(result).to eq(expected)
        class ToFieldValue
          # @param field [Symbol] name of field to append to
          # @param value [String] value to append to existing field values
          # @param delim [String, nil] indicates multivalue delimiter on which
          #   to split values, if given
          def initialize(field:, value:, delim: nil)
            @field = field
            @value = value
            @delim = delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fv = row.fetch(@field, nil)
            return row if fv.blank?

            vals = @delim ? fv.split(@delim) : [fv]
            row[@field] = vals.map { |fieldval| "#{fieldval}#{@value}" }
              .join(@delim)
            row
          end
        end
      end
    end
  end
end
