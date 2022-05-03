# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        class ConstantValue
          def initialize(target:, value:)
            @target = target
            @value = value
          end

          # @private
          def process(row)
            row[@target] = @value
            row
          end
        end
      end
    end
  end
end
