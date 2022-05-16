# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # Merges given value into the given target field in every row. Target field is added new. If it already exists,
        #   values in target field are overridden by contant value. 
        class ConstantValue
          include SingleWarnable
          # @param target [Symbol] target field in which to enter constant value
          # @param value [String] the constant value to enter in target field 
          def initialize(target:, value:)
            @target = target
            @value = value
            setup_single_warning
          end

          # @private
          def process(row)
            unless row.fetch(target, nil).blank?
              add_single_warning("Any values in existing `#{target}` field will be overwritten with `#{value}`")
            end
            
            row[target] = value
            row
          end

          private

          attr_reader :target, :value
        end
      end
    end
  end
end
