# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Adds values to the end of fields or rows
      module Append
        ::Append = Kiba::Extend::Transforms::Append
        class NilFields
          def initialize(fields:)
            @fields = fields
          end

          # @private
          def process(row)
            @fields.each do |field|
              row[field] = nil unless row.key?(field)
            end
            row
          end
        end

        class ToFieldValue
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
