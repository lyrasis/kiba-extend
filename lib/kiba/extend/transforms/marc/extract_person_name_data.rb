# frozen_string_literal: true

# rubocop:todo Layout/LineLength

require "marc"

module Kiba
  module Extend
    module Transforms
      module Marc
        # Extract :marcid and person name data (name, role term, role code,
        #   source field tag) from fields containing structured name data
        #
        # @example
        #   # =001  008001024-5
        #   # =100  1\$6880-03$aGlinka, M. I.$q(Mikhail Ivanovich),$d1804-1857,$ecomposer.$4cmp
        #   # =700  1\$aBrussilovsky, Alexandre,$eperformer # no 880
        #   # =880  1\$6100-03$aGlinka VERN,$ecomposer.$4cmp
        #   rec = get_marc_record(index: 9)
        #   xform = Marc::ExtractPersonNameData.new
        #   results = []
        #   xform.process(rec){ |row| results << row }
        #   expect(results.length).to eq(12)
        #   first = {
        #     :sourcefield=>"700", :name=>"Brussilovsky, Alexandre",
        #     :nametype=>"person", :role_code=>"", :role_term=>"performer",
        #     :marcid=>"008001024-5"
        #   }
        #   last = {
        #     :sourcefield=>"100", :name=>"Glinka VERN", :nametype=>"person",
        #     :role_code=>"cmp", :role_term=>"composer", :marcid=>"008001024-5"
        #   }
        #   expect(results[0]).to eq(first)
        #   expect(results[-1]).to eq(last)
        #
        # @since 4.0.0
        class ExtractPersonNameData < ExtractBaseNameData
          # @param name_type [String] to insert into name_type_target field
          # @param name_fields [Array<String>] MARC fields from which name data
          #   will be extracted
          # @param name_subfields [Array<String>] subfields to extract
          #   as part of name value.
          # @param role_code_subfields [Array<String>] subfields to extract as
          #   role code value
          # @param role_term_subfields [Array<String>] subfields to extract as
          #   role term value
          def initialize(name_type: "person",
            name_fields: Kiba::Extend::Marc.person_data_tags,
            name_subfields:
            Kiba::Extend::Marc.person_name_part_subfields,
            role_code_subfields:
            Kiba::Extend::Marc.person_role_code_subfields,
            role_term_subfields:
            Kiba::Extend::Marc.person_role_term_subfields)
            super
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
