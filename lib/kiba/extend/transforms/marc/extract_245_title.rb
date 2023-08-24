# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Transforms
      module Marc
        # Extract title fields from 245 (and/or linked 880) fields, along with
        #   :marcid value
        #
        # @example Just 245
        #   # 245 13 $a Un sextuor pour piano et cordes en mi bémol majeur
        #   # $h [sound recording] ; $b Divertimento sur des thémes de la
        #   # Somnanbula de Bellini ; Sérénade sur des thémes d'Anna Bolena de
        #   # Donizetti / $c Mikhail Glinka.
        #   rec = get_marc_record(index: 9)
        #   xform = Marc::Extract245Title.new
        #   result = xform.process(rec)[:title]
        #   expected = "Un sextuor pour piano et cordes en mi bémol majeur ; Divertimento sur des thémes de la Somnanbula de Bellini ; Sérénade sur des thémes d'Anna Bolena de Donizetti"
        #   expect(result).to eq(expected)
        # @example Deleting non-filing characters
        #   # Same MARC data as above example
        #   rec = get_marc_record(index: 9)
        #   xform = Marc::Extract245Title.new(delete_non_filing: true)
        #   result = xform.process(rec)[:title]
        #   expected = "sextuor pour piano et cordes en mi bémol majeur ; Divertimento sur des thémes de la Somnanbula de Bellini ; Sérénade sur des thémes d'Anna Bolena de Donizetti"
        #   expect(result).to eq(expected)
        # @example Deleting non-filing characters and upcasing first char
        #   # Same MARC data as above example
        #   rec = get_marc_record(index: 9)
        #   xform = Marc::Extract245Title.new(
        #     delete_non_filing: true,
        #     upcase_first_filing_char: true
        #   )
        #   result = xform.process(rec)[:title]
        #   expected = "Sextuor pour piano et cordes en mi bémol majeur ; Divertimento sur des thémes de la Somnanbula de Bellini ; Sérénade sur des thémes d'Anna Bolena de Donizetti"
        #   expect(result).to eq(expected)
        # @example 880 and Preferring vernacular
        #   # 245 10 $6 880-02 $a Jidō shinri hen / $c Nihon Ryōshin Saikyōiku
        #   #   Kyōkai hen.
        #   # 880 10 $6 245-02 $a 兒童心理篇 / $c 日本兩親再教育協會編.
        #   rec = get_marc_record(index: 6)
        #   xform = Marc::Extract245Title.new
        #   result = xform.process(rec)[:title]
        #   expected = '兒童心理篇'
        #   expect(result).to eq(expected)
        # @example 880 and not preferring vernacular
        #   # Same MARC data as above example
        #   rec = get_marc_record(index: 6)
        #   Kiba::Extend::Marc.config.prefer_vernacular = false
        #   xform = Marc::Extract245Title.new
        #   result = xform.process(rec)[:title]
        #   Kiba::Extend::Marc.reset_config
        #   expected = 'Jidō shinri hen|兒童心理篇'
        #   expect(result).to eq(expected)
        #
        # @since 3.3.0
        class Extract245Title
          # @param id_target [Symbol] row field into which id value will be
          #   written
          # @param title_target [Symbol] row field into which title value will
          #   be written
          # @param title_subfields [Array<String>] subfields of 245 to extract
          #   as part of title value. NOTE: Any `space-punctuation-space?` at
          #   the end of a $h is retained as part of title if $h itself is not
          #   included as part of title
          # @param delim [String] used when joining values from multiple fields
          # @param delete_non_filing [Boolean] if true, removes nonfiling
          #   characters as specified in 245 2nd indicator
          # @param upcase_first_filing_char [Boolean] if true, upcases the
          #   first character of each title after non-filing characters are
          #   deleted. Has no effect if you are not deleting non-filing chars.
          def initialize(id_target: Kiba::Extend::Marc.id_target_field,
            title_target: :title,
            title_subfields:
            Kiba::Extend::Marc.title_part_subfields,
            delim: Kiba::Extend.delim,
            delete_non_filing: false,
            upcase_first_filing_char: false)
            @id_target = id_target
            @title_target = title_target
            @title_subfields = title_subfields
            @delim = delim
            @delete_non_filing = delete_non_filing
            @upcase_first_filing_char = upcase_first_filing_char
            @idextractor = Kiba::Extend::Utils::MarcIdExtractor.new
          end

          # @param record [MARC::Record]
          # @return [Hash{ Symbol => String, nil }]
          def process(record)
            id = idextractor.call(record)
            row = {id_target => id}
            row[title_target] = title_value(record)
            row
          end

          private

          attr_reader :id_target, :title_target, :title_subfields, :delim,
            :delete_non_filing, :upcase_first_filing_char, :idextractor

          def title_value(record)
            title_fields(record)
              .map { |field| title(field) }
              .join(delim)
          end

          def title_fields(record)
            normal = record.find_all { |field| field.tag == "245" }
            linked = Kiba::Extend::Marc.linked_fields(record, "245")
            return normal if linked.empty?

            if Kiba::Extend::Marc.prefer_vernacular
              linked
            else
              normal + linked
            end
          end

          def title(field)
            val = field.subfields
              .map { |sf| replace_subfield_value(sf) }
              .compact
              .map { |sf| remove_preceding_sor_slash(sf) }
              .map { |sf| sf.value }
              .join(" ")
              .gsub(/  +/, " ")
            delete_non_filing ? delete_nonfiling(val, field.indicator2) : val
          end

          def delete_nonfiling(val, nonfiling)
            filing = val[(nonfiling.to_i)..-1]
            upcase_first_filing_char ? upcase(filing) : filing
          end

          def upcase(val)
            words = val.split(" ")
            firstword = words.shift
            remaining = words.join(" ")
            letters = firstword.split("")
            letters.first.upcase!
            [letters.join, remaining].join(" ")
          end

          def replace_subfield_value(subfield)
            return subfield if title_subfields.any?(subfield.code)

            if subfield.code == "h"
              replace_sf_h(subfield)
            end
          end

          def replace_sf_h(subfield)
            val = subfield.value.match(/( \W ?)$/)
            return nil if val.nil?

            subfield.value = val[1]
            subfield
          end

          def remove_preceding_sor_slash(subfield)
            return subfield unless %w[a b].any?(subfield.code)
            return subfield unless subfield.value.match?(/ \/ ?$/)

            val = subfield.value.sub(/ \/ ?$/, "")
            subfield.value = val
            subfield
          end
        end
      end
    end
  end
end
