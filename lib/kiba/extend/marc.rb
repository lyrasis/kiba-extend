# frozen_string_literal: true

module Kiba
  module Extend
    module Marc
      module_function
      extend Dry::Configurable

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
