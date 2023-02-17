# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Utils
      # Callable service to generate a fingerprint value from the given fields
      # @since 2.7.1.65
      class MarcIdExtractor
        class ControlFieldsDoNotHaveSubfieldsError < Kiba::Extend::Error; end

        def initialize
          @tag = Kiba::Extend::Marc.id_tag
          @subfield = Kiba::Extend::Marc.id_subfield
          if subfield && MARC::ControlField.control_tags.any?(tag)
            raise ControlFieldsDoNotHaveSubfieldsError
          end

          @field_selector = Kiba::Extend::Marc.id_field_selector
          @subfield_selector = Kiba::Extend::Marc.id_subfield_selector
          @value_formatter = Kiba::Extend::Marc.id_value_formatter
        end

        # @param record [MARC::Record]
        # @return [String]
        def call(record)
          fields = candidate_fields(record)
          return nil if fields.empty?

          selected_fields = get_selected_fields(fields)
          values = get_values(selected_fields)
          value_formatter.call(values)
        end

        private

        attr_reader :tag, :subfield, :field_selector, :subfield_selector,
          :value_formatter

        def candidate_fields(record)
          if subfield
            candidates = fields_with_tag(record)
              .select{ |fld| fld.codes.any?(subfield) }
            return candidates unless subfield_selector

            fields_with_eligible_subfields(candidates)
          else
            fields_with_tag(record)
          end
        end

        def fields_with_eligible_subfields(fields)
          fields.select do |field|
            test = field.subfields.select{ |sf|
              sf.code == subfield && subfield_selector.call(sf.value)
            }
            !test.empty?
          end
        end

        def selected_subfields(subfields)
          return subfields unless subfield_selector

          subfields.select{ |sf| subfield_selector.call(sf.value) }
        end

        def fields_with_tag(record)
          record.find_all{ |field| field.tag == tag}
        end

        def get_selected_fields(fields)
          return fields unless field_selector

          field_selector.call(fields)
        end

        def subfields(fields)
          fields.map{ |field| field.subfields }
            .flatten
            .select{ |subf| subf.code == subfield }
        end

        def get_values(fields)
          return fields.map(&:value) unless subfield

          selected_subfields(subfields(fields)).map(&:value)
        end
      end
    end
  end
end
