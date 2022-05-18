# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that remove rows based on different types of conditions
      module FilterRows
        ::FilterRows = Kiba::Extend::Transforms::FilterRows

        class FieldPopulated
          def initialize(action:, field:)
            @action = action
            @field = field
          end

          # @private
          def process(row)
            val = row.fetch(@field, nil)
            case @action
            when :keep
              val.nil? || val.empty? ? nil : row
            when :reject
              val.nil? || val.empty? ? row : nil
            end
          end
        end

        class FieldValueGreaterThan
          def initialize(action:, field:, value:)
            @action = action
            @field = field
            @value = value
          end

          # @private
          def process(row)
            val = row.fetch(@field)
            case @action
            when :keep
              val > @value ? row : nil
            when :reject
              val > @value ? nil : row
            end
          end
        end
      end
    end
  end
end
