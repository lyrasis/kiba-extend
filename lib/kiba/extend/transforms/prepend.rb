module Kiba
  module Extend
    module Transforms
      module Prepend
        ::Prepend = Kiba::Extend::Transforms::Prepend
        class ToFieldValue
          def initialize(field:, value:)
            @field = field
            @value = value
          end

          def process(row)
            fv = row.fetch(@field, nil)
            return row if fv.blank?
            row[@field] = "#{@value}#{fv}"
            row
          end
        end
      end
    end
  end
end
