# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        # Extract :marcid values from all records in file based on config
        #   settings defined in {Kiba::Extend::Marc}
        #
        # @example
        #   rec = get_marc_record(index: 0)
        #   xform = Marc::ExtractIds.new
        #   result = xform.process(rec)
        #   expected = "008000103-3"
        #   expect(result[Kiba::Extend::Marc.id_target_field]).to eq(expected)
        class ExtractIds
          # @param id_target [Symbol] row field into which id value will be
          #   written
          def initialize(id_target: Kiba::Extend::Marc.id_target_field)
            @id_target = id_target
            @idextractor = Kiba::Extend::Utils::MarcIdExtractor.new
          end

          # @param record [MARC::Record]
          # @return [Hash{ Symbol => String, nil }]
          def process(record)
            row = {id_target=>idextractor.call(record)}
            row
          end

          private

          attr_reader :id_target, :idextractor

        end
      end
    end
  end
end
