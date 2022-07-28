# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Reshape
        # @deprecated In 2.9.0. Use {Collapse::FieldsToTypedFieldPair} instead.
        class CollapseMultipleFieldsToOneTypedFieldPair
          def initialize(sourcefieldmap:, datafield:, typefield:, targetsep:, sourcesep: nil, delete_sources: true)
            @replacement = Collapse::FieldsToTypedFieldPair.new(
              sourcefieldmap: sourcefieldmap,
              datafield: datafield,
              typefield: typefield,
              targetsep: targetsep,
              sourcesep: sourcesep,
              delete_sources: delete_sources
            )
            msg = 'Reshape::CollapseMultipleFieldsToOneTypedFieldPair to be deprecated in a future release. Convert any usage of this transform to Collapse::FieldsToTypedFieldPair'
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
