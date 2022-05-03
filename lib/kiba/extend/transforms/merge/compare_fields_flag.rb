# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Merge
        # @deprecated Use {Compare::FieldValues} instead.
        class CompareFieldsFlag
          def initialize(...)
            warn('DEPRECATED TRANSFORM. Use Compare::FieldValues instead')
            @xform = Compare::FieldValues.new(...)
          end

          # @private
          def process(row)
            xform.process(row)
          end

          private
          
          attr_reader :xform
        end
      end
    end
  end
end
