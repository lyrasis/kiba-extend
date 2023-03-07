# frozen_string_literal: true

require 'marc'

module Kiba
  module Extend
    module Transforms
      module Marc
        # Base class with shared name extraction behaviors
        # @abstract
        class ExtractBaseNameData
          include FieldLinkable
          # @param name_type [String] to insert into name_type_target field
          # @param id_target [Symbol] row field into which id value will be
          #   written
          # @param name_target [Symbol] row field into which name value will
          #   be written
          # @param role_term_target [Symbol] row field into which role term
          #   value will be written
          # @param role_code_target [Symbol] row field into which role code
          #   value will be written
          # @param field_tag_target [Symbol] row field into which field tag
          #   value will be written
          # @param name_type_target [Symbol] row field into which name type
          #   value will be written
          # @param name_fields [Array<String>] MARC fields from which name data
          #   will be extracted
          # @param name_subfields [Array<String>] subfields to extract
          #   as part of name value.
          # @param role_code_subfields [Array<String>] subfields to extract as
          #   role code value
          # @param role_term_subfields [Array<String>] subfields to extract as
          #   role term value
          # @param delim [String] used when joining multiple values in a field
          def initialize(name_type:,
                         id_target: Kiba::Extend::Marc.id_target_field,
                         name_target: Kiba::Extend::Marc.name_target,
                         role_term_target: Kiba::Extend::Marc.role_term_target,
                         role_code_target: Kiba::Extend::Marc.role_code_target,
                         field_tag_target: Kiba::Extend::Marc.field_tag_target,
                         name_type_target: Kiba::Extend::Marc.name_type_target,
                         name_fields:, name_subfields:, role_code_subfields:,
                         role_term_subfields:,
                         delim: Kiba::Extend.delim
                        )
            @name_type = name_type
            @id_target = id_target
            @name_target = name_target
            @role_term_target = role_term_target
            @role_code_target = role_code_target
            @field_tag_target = field_tag_target
            @name_type_target = name_type_target
            @name_fields = name_fields
            @name_subfields = name_subfields
            @role_term_subfields = role_term_subfields
            @role_code_subfields = role_code_subfields
            @delim = delim
            @idextractor = Kiba::Extend::Utils::MarcIdExtractor.new
            @namecleaner = Kiba::Extend::Utils::MarcNameCleaner.new
            @roletermcleaner = Kiba::Extend::Utils::MarcRoleTermCleaner.new
          end

          # @param record [MARC::Record]
          # @return [Hash{ Symbol => String, nil }]
          def process(record)
            prepare_rows(record).each do |row|
              yield row
            end

            nil
          end

          private

          attr_reader :name_type, :id_target, :name_target, :role_code_target,
            :role_term_target, :field_tag_target, :name_type_target,
            :name_fields, :name_subfields, :role_code_subfields,
            :role_term_subfields, :delim, :idextractor, :namecleaner,
            :roletermcleaner

          def prepare_rows(record)
            idhash = {id_target=>idextractor.call(record)}
            select_fields(record, name_fields)
              .map{ |fld| name_data_hash(fld) }
              .map{ |row| row.merge(idhash) }
              .uniq
          end

          def name_data_hash(field)
            {
              field_tag_target=>field.tag,
              name_target=>namecleaner.call(name(field)),
              name_type_target=>name_type,
              role_code_target=>role_code(field),
              role_term_target=>role_term(field)
            }
          end

          def name(field)
            field.subfields
              .select{ |sf| name_subfields.any?(sf.code) }
              .map{ |sf| sf.value.strip }
              .join(' ')
              .gsub(/  +/, ' ')
          end

          def role_code(field)
            field.subfields
              .select{ |sf| role_code_subfields.any?(sf.code) }
              .map{ |sf| sf.value.strip }
              .join(Kiba::Extend.delim)
          end

          def role_term(field)
            field.subfields
              .select{ |sf| role_term_subfields.any?(sf.code) }
              .map{ |sf| roletermcleaner.call(sf.value.strip) }
              .join(Kiba::Extend.delim)
          end
        end
      end
    end
  end
end
