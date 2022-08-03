# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations that remove rows based on different types of conditions
      module FilterRows
        ::FilterRows = Kiba::Extend::Transforms::FilterRows

        # @deprecated Convert any uses of this transform in your jobs to
        #   {Kiba::Extend::Transforms::FilterRows::WithLambda}
        class FieldValueGreaterThan
          def initialize(action:, field:, value:)
            warn("#{self.class.name} will be removed in a future version. Convert to `FilterRows::WithLambda`", category: :deprecated)
            @action = action
            @field = field
            @value = value
          end

          # @param row [Hash{ Symbol => String }]
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
