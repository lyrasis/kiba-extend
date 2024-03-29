# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Transforms
      module Marc
        # Extract :marcid and org name data (name, role term, role code,
        #   source field tag) from fields containing structured name data
        #
        # @example
        #   # =001  008000411-3
        #   # =110  2\$aH.M. Gousha Company.
        #   rec = get_marc_record(index: 3)
        #   xform = Marc::ExtractOrgNameData.new
        #   results = []
        #   xform.process(rec){ |row| results << row }
        #   row = {:sourcefield=>"110", :name=>"H.M. Gousha Company",
        #         :nametype=>"org", :role_code=>"", :role_term=>"",
        #         :marcid=>"008000411-3"}
        #   expect(results.length).to eq(1)
        #   expect(results.first).to eq(row)
        #
        # @since 4.0.0
        class ExtractOrgNameData < ExtractBaseNameData
          # @param name_type [String] to insert into name_type_target field
          # @param name_fields [Array<String>] MARC fields from which name data
          #   will be extracted
          # @param name_subfields [Array<String>] subfields to extract
          #   as part of name value.
          # @param role_code_subfields [Array<String>] subfields to extract as
          #   role code value
          # @param role_term_subfields [Array<String>] subfields to extract as
          #   role term value
          def initialize(name_type: "org",
            name_fields: Kiba::Extend::Marc.org_data_tags,
            name_subfields:
            Kiba::Extend::Marc.org_name_part_subfields,
            role_code_subfields:
            Kiba::Extend::Marc.org_role_code_subfields,
            role_term_subfields:
            Kiba::Extend::Marc.org_role_term_subfields)
            super
          end
        end
      end
    end
  end
end
