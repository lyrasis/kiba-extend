# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Append
        # Adds the given field(s) to the row with nil value if they do not
        #   already exist in row
        #
        # @example
        #   # Used in pipeline as:
        #   # transform Append::NilFields, fields: %i[a b z]
        #
        #   xform = Append::NilFields.new(fields: %i[a b z])
        #   input = [{z: "zz"}]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [{z: "zz", a: nil, b: nil}]
        #   expect(result).to eq(expected)
        class NilFields
          # @param fields [Array<Symbol>, Symbol] field name or list of field
          #   names to add
          def initialize(fields:)
            @fields = [fields].flatten
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            @fields.each do |field|
              row[field] = nil unless row.key?(field)
            end
            row
          end
        end
      end
    end
  end
end
