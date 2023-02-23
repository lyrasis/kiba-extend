# frozen_string_literal: true

module Kiba
  module Extend
    # @since 3.3.0
    # Configuration and shared methods for MARC data
    module Marc
      module_function
      extend Dry::Configurable

      # @return [Symbol] field in which the write the field tag value from
      #   which data was extracted when converting MARC data to Hash row
      setting :field_tag_target, default: :sourcefield, reader: true
      # @return [String] the MARC field tag from which id value is extracted
      setting :id_tag, default: '001', reader: true
      # @return [Proc, nil] Code to perform any further selection from the Array
      #   of fields having the configured {id_tag}, after any given
      #   {id_subfield} and {id_subfield_selector} constraints have been
      #   met in the field selection.
      #
      #   The Proc should take one argument, which is an Array of
      #   MARC::ControlField or MARC::DataField objects.
      #
      #   The Proc should return an Array of MARC::ControlField or
      #   MARC::DataField objects.
      setting :id_field_selector,
        default: ->(fields){ [fields.first] },
        reader: true
      # @return [String] subfield of :id_tag field from which to extract
      #   id
      setting :id_subfield, default: nil, reader: true
      # @return [Proc, nil] Code specifying criteria a subfield value must meet
      #   in order to be selected as a MARC ID value. Eg. must begin with
      #   `(OCoLC)`
      #
      # The Proc should take one argument, which is a String (usually derived by
      #   calling `MARC::Subfield.value`.
      #
      # The Proc should return `TrueClass` or `FalseClass`
      setting :id_subfield_selector, default: nil, reader: true
      # @return [Proc] Code specifying how to transform values extracted from
      #   {id_tag}/{id_subfield} into a final ID string.
      #
      # The Proc should take one argument, which is an Array of Strings.
      #
      # The Proc should return a String.
      setting :id_value_formatter,
        default: ->(values){ values.first },
        reader: true
      # @return [Symbol] field in which to write the MARC id value when
      #   converting MARC data to CSV row
      setting :id_target_field, default: :marcid, reader: true
      # @return [Array<String>] MARC field tags for fields that contain the
      #   structured meeting name data pattern documented at
      #   https://www.loc.gov/marc/bibliographic/bdx11.html
      setting :meeting_data_tags,
        default: %w[111 611 711 811],
        reader: true
      # @return [Array<String>] subfields to be extracted as part of name values
      #   from {meeting_data_tags}
      setting :meeting_name_part_subfields,
        default: %w[a b c d g n u],
        reader: true
      # @return [Array<String>] subfields to be extracted as meeting role codes
      #   from {meeting_data_tags}
      setting :meeting_role_code_subfields,
        default: %w[4],
        reader: true
      # @return [Array<String>] subfields to be extracted as meeting role terms
      #   from {meeting_data_tags}
      setting :meeting_role_term_subfields,
        default: %w[e],
        reader: true
      # @return [Symbol] field in which to write the name value when
      #   converting MARC data to CSV row when extracting names
      setting :name_target, default: :name, reader: true
      # @return [Symbol] field in which to write the name type value when
      #   converting MARC data to CSV row when extracting names
      setting :name_type_target, default: :nametype, reader: true
      # @return [Array<String>] MARC field tags for fields that contain the
      #   structured org name data pattern documented at
      #   https://www.loc.gov/marc/bibliographic/bdx10.html
      setting :org_data_tags,
        default: %w[110 610 710 810],
        reader: true
      # @return [Array<String>] subfields to be extracted as part of name values
      #   from {org_data_tags}
      setting :org_name_part_subfields,
        default: %w[a b c d g n u],
        reader: true
      # @return [Array<String>] subfields to be extracted as org role codes
      #   from {org_data_tags}
      setting :org_role_code_subfields,
        default: %w[4],
        reader: true
      # @return [Array<String>] subfields to be extracted as org role terms
      #   from {org_data_tags}
      setting :org_role_term_subfields,
        default: %w[e],
        reader: true
      # @return [Array<String>] MARC field tags for fields that contain the
      #   structured person name data pattern documented at
      #   https://www.loc.gov/marc/bibliographic/bdx00.html
      setting :person_data_tags,
        default: %w[100 600 700 800],
        reader: true
      # @return [Array<String>] subfields to be extracted as part of name values
      #   from {person_data_tags}
      setting :person_name_part_subfields,
        default: %w[a b c d j q u],
        reader: true
      # @return [Array<String>] subfields to be extracted as person role codes
      #   from {person_data_tags}
      setting :person_role_code_subfields,
        default: %w[4],
        reader: true
      # @return [Array<String>] subfields to be extracted as person role terms
      #   from {person_data_tags}
      setting :person_role_term_subfields,
        default: %w[e],
        reader: true
      # @return [Boolean] If true, returns linked 880 field values instead of
      #   main field (transliterated values). If false, returns main field
      #   value, followed by 880 field value
      setting :prefer_vernacular, default: true, reader: true
      # @return [Symbol] field in which to write the role code value when
      #   converting MARC data to CSV row for name extraction
      setting :role_code_target, default: :role_code, reader: true
      # @return [Symbol] field in which to write the role term value when
      #   converting MARC data to CSV row for name extraction
      setting :role_term_target, default: :role_term, reader: true
      # @return [Array<String>] subfields to be extracted as part of title
      #   from 245 fields
      setting :title_part_subfields,
        default: %w[a b f g k n p s],
        reader: true

      # @param record [MARC::Record]
      # @param tag [String] of normal MARC field, e.g. '245'
      # @return [Array<MARC::DataField>] 880 fields linked to fields with given
      #   tag
      def linked_fields(record, tag)
        record.find_all do |field|
          field.tag == '880' && field['6'].start_with?(tag)
        end
      end
    end
  end
end
