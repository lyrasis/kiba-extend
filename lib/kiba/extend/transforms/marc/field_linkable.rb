# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        # Mix-in module providing methods for dealing with identifying
        #   and extracting data from linked transliterated and vernacular
        #   (e.g. 880) fields in MARC data
        module FieldLinkable

          # @param record [MARC::Record]
          # @param tags [Array<String>]
          # @return [Array<MARC::ControlField,MARC::DataField>]
          def select_fields(record, tags)
            all = candidate_fields(record, tags)
              .map{ |field| add_linkage_data(field) }
            preferred(all)
              .map{ |fldhsh| update_tag(fldhsh) }
              .map{ |fldhsh| fldhsh[:datafield] }
          end

          private

          def update_tag(fieldhash)
            fieldhash[:datafield].tag =
              fieldhash[Kiba::Extend::Marc.field_tag_target]
            fieldhash
          end

          # @param record [MARC::Record]
          # @param tags [Array<String>]
          # @return [Array<MARC::ControlField,MARC::DataField>]
          def candidate_fields(record, tags)
            select_main_fields(record, tags) +
              select_vernacular_fields(record, tags)
          end

          # @param field [MARC::DataField]
          # @return [Hash] with linkage data merged in
          def add_linkage_data(field)
            if linked?(field)
              {datafield: field}.merge(linkage_data(field))
            else
              {datafield: field}.merge(non_linkage_data(field))
            end
          end

          # @param fieldhashes [Array<Hash>]
          # @return [Array<Hash>] removes transliterated fieldhashes if
          #  vernacular is preferred
          def preferred(fieldhashes)
            return fieldhashes if fieldhashes.empty?
            return fieldhashes unless Kiba::Extend::Marc.prefer_vernacular

            linked = fieldhashes.select{ |row| row[:linked] }
            return fieldhashes if linked.empty?

            fieldhashes - non_preferred_field_data(linked)
          end

          # @param row [Hash]
          # return [Hash] row with added linkage data removed
          def delete_linkage_data(row)
            non_linkage_data.keys.each{ |key| row.delete(key) }
            row
          end

          # @param field [MARC::DataField]
          # @return [String]
          def extract_tag(field)
            if vernacular?(field)
              field['6'].split('-').first
            else
              field.tag
            end
          end

          # @param field [MARC::DataField]
          # @param tag [String]
          # @return [String]
          def extract_link_id(field, tag)
            return field['6'] if vernacular?(field)

            id = field['6'].split('-').last
            "#{tag}-#{id}"
          end

          # @param field [MARC::DataField]
          # @return [Hash]
          def linkage_data(field)
            tag = extract_tag(field)
            {
              linked: linked?(field),
              vernacular: vernacular?(field),
              Kiba::Extend::Marc.field_tag_target=>tag,
              linkid: extract_link_id(field, tag)
            }
          end

          # @return [Hash]
          def non_linkage_data(field)
            {
              linked: false,
              linkid: nil,
              vernacular: nil,
              Kiba::Extend::Marc.field_tag_target=>extract_tag(field)
            }
          end

          def non_preferred_field_data(rows)
            rows.group_by{ |row| row[:linkid] }
              .values
              .select{ |arr| arr.length == 2 }
              .flatten
              .reject{ |row| row[:vernacular] }
          end

          def select_main_fields(record, tags)
            record.find_all{ |fld| tags.any?(fld.tag) }
          end

          def select_vernacular_fields(record, tags)
            return [] if record.tags.none?('880')

            record.find_all{ |fld| fld.tag == '880' }
              .select do |fld|
                tags.any?(fld['6'][0..2])
              end
          end

          # @param field [MARC::DataField]
          # @return [Boolean]
          def linked?(field)
            field.codes.any?('6')
          end

          # @param field [MARC::DataField]
          # @return [Boolean]
          def transliterated?(field)
            !vernacular?(field)
          end

          # @param field [MARC::DataField]
          # @return [Boolean]
          def vernacular?(field)
            return true if field.tag == '880'

            false
          end
        end
      end
    end
  end
end
