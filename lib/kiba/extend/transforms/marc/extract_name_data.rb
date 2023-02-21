# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        # Extract :marcid and person name data (name, role term, role code,
        #   source field tag) from fields containing structured name data
        #
        # @example
        #   rec = get_marc_record(index: 6)
        #   xform = Marc::ExtractNameData.new
        #   results = []
        #   xform.process(rec){ |row| results << row }
        #   expect(results.length).to eq(3)
        class ExtractNameData
          def initialize
            @extractors = [
              Marc::ExtractPersonNameData.new,
              Marc::ExtractOrgNameData.new,
              Marc::ExtractMeetingNameData.new,
            ]
          end

          def process(record)
            rows = []
            extractors.each do |extractor|
              extractor.process(record){ |row| rows << row }
            end
            rows.each{ |row| yield row }
            nil
          end

          private

          attr_reader :extractors
        end
      end
    end
  end
end
