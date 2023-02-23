# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        module FieldLinkable
          # @param field [MARC::DataField]
          # @param row [Hash]
          # @return [Hash] row with linkage data merged in
          def add_linkage_data(field, row)
            if linked?(field)
              row.merge(linkage_data(field))
            else
              row.merge(non_linkage_data)
            end
          end

          def delete_linkage_data(row)
            non_linkage_data.keys.each{ |key| row.delete(key) }
            row
          end

          # @param field [MARC::DataField]
          # @return [Boolean]
          def linked?(field)
            field.codes.any?('6')
          end

          def preferred(rows)
            return rows if rows.empty?
            return rows unless Kiba::Extend::Marc.prefer_vernacular

            linked = rows.select{ |row| row[:linked] }
            return rows if linked.empty?

            rows - non_preferred_field_data(linked)
          end

          def select_fields(record, tags)
            select_main_fields(record, tags) +
              select_vernacular_fields(record, tags)
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

          private

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
          def non_linkage_data
            {
              linked: false,
              linkid: nil,
              vernacular: nil
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
        end
      end
    end
  end
end
