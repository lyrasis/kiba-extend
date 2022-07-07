# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module CombineValues
        # @deprecated In 2.9.0. Use {Collapse::FieldsWithCustomFieldmap} instead.
        class AcrossFieldGroup
          def initialize(fieldmap:, sep:, delete_sources: true)
            @replacement = Collapse::FieldsWithCustomFieldmap.new(
              fieldmap: fieldmap,
              delim: sep,
              delete_sources: delete_sources
            )
            msg = 'CombineValues::AcrossFieldGroup to be deprecated in a future release. Convert any usage of this transform to Collapse::FieldsWithCustomFieldmap'
            warn("#{Kiba::Extend.warning_label}: #{msg}")
          end

          # @private
          def process(row)
            replacement.process(row)
          end

          private

          attr_reader :replacement
        end
      end
    end
  end
end
