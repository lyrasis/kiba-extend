module Kiba
  module Extend
    module Transforms
      module Append
        ::Append = Kiba::Extend::Transforms::Append
        class ToFieldValue
          def initialize(field:, value:)
            @field = field
            @value = value
          end

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
