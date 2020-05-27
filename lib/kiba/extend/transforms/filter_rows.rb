module Kiba
  module Extend
    module Transforms
      module FilterRows
        ::FilterRows = Kiba::Extend::Transforms::FilterRows
        class FieldEqualTo
          def initialize(action:, field:, value:)
            @column = field
            @value = value
            @action = action
          end

          def process(row)
            case @action
            when :keep
              row.fetch(@column) == @value ? row : nil
            when :reject
              row.fetch(@column) == @value ? nil : row
            end
          end
        end

        class FieldPopulated
          def initialize(action:, field:)
            @action = action
            @field = field
          end

          def process(row)
            val = row.fetch(@field)
            case @action
            when :keep
              val.nil? || val.empty? ? nil : row
            when :reject
              val.nil? || val.empty? ? row : nil
            end
          end
        end
      end
    end
  end
end
