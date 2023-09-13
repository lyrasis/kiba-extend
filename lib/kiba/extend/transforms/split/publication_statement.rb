# frozen_string_literal: true

require "strscan"

# rubocop:todo Layout/LineLength
module Kiba
  module Extend
    module Transforms
      module Split
        # Splits string value of given field into new `:pubplace`, `:publisher`,
        #   `:pubdate`, `:manplace`, `:manufacturer`, and `:mandate` fields.
        #   Fieldnames can be overridden.
        #
        # Splitting is based on expected ISBD punctuation used in the MARC 260
        #   field.
        #
        # This transform does the best it can, but depends on fiddly punctuation
        #   standards that are not always followed, and which are sometimes
        #   ambiguous when MARC subfield coding is not present. It is intended
        #   for use in preparing data for client review and cleanup.
        #
        # Algorithm/assumptions:
        #
        # - Terminal period is removed from field value pre-processing
        # - If field value starts with a digit, the whole field value is treated
        #   as a date
        # - If field value contains a `:` or `;`, followed by the pattern `comma
        #   followed by non-comma characters and one or more digits`, then
        #   everything including and following that pattern is treated as the
        #   date value
        # - If a field value contains `:` or `;`, we treat the first segment of
        #   the value as place
        # - If a field value does not contain `:` or `;`, and does not begin
        #   with a digit, we treat the whole field value as publisher
        # - Any part of the field value in parentheses is extracted separately
        #   and checked for whether it follows the above patterns. If so, it is
        #   run through processing as manufacturing data, and the
        #   non-parenthetical data is run through the processing as publication
        #   data. If parenthetical data does not match one of the patterns,
        #   it gets included as part of publication place, name, or date field
        #
        # ## Usage in jobs
        #
        # ~~~
        # transform Split::PublicationStatement, source: :pubstmt
        # ~~~
        #
        # ~~~
        # transform Split::PublicationStatement,
        #   source: :pubstmt,
        #   fieldname_overrides: {manufacturer: :printer, mandate: :printdate},
        #   delim: '%'
        # ~~~
        #
        # @example Default fieldnames, demonstrating parsing/splitting behavior
        #   input = [
        #     {ps: 'Belfast [i.e. Dublin : s.n.], 1946 [reprinted 1965]'},
        #     {ps: 'Harmondsworth : Penguin, 1949 (1963 printing)'},
        #     {ps: 'Wash, D.C. (16 K St., N., Wash 20006) : Wider , 1979 printing, c1975.'},
        #     {ps: 'American Issue Publishing Company'},
        #     {ps: 'Chicago : New Voice Press, ©1898.'},
        #     {ps: 'New York ; Berlin : Springer Verlag, 1977.'},
        #     {ps: 'Columbus : The League'},
        #     {ps: '1908-1924.'},
        #     {ps: 'Paris : Rue ; London : Press, 1955'},
        #     {ps: 'Chicago, etc. : Time Inc.'},
        #     {ps: 'Paris : Impr. Vincent, 1798 [i.e. Bruxelles : Moens, 1883]'},
        #     {ps: 'London : Council, 1976 (Twickenham : CTD Printers, 1974)'}
        #   ]
        #   expected = [
        #     {ps: 'Belfast [i.e. Dublin : s.n.], 1946 [reprinted 1965]',
        #      pubplace: 'Belfast [i.e. Dublin', publisher: 's.n.]',
        #      pubdate: '1946 [reprinted 1965]', manplace: nil,
        #      manufacturer: nil, mandate: nil},
        #     {ps: 'Harmondsworth : Penguin, 1949 (1963 printing)',
        #      pubplace: 'Harmondsworth', publisher: 'Penguin',
        #      pubdate: '1949', manplace: nil, manufacturer: nil,
        #      mandate: '1963 printing'},
        #     {ps: 'Wash, D.C. (16 K St., N., Wash 20006) : Wider , 1979 printing, c1975.',
        #      pubplace: 'Wash, D.C. (16 K St., N., Wash 20006)',
        #      publisher: 'Wider', pubdate: '1979 printing, c1975',
        #      manplace: nil, manufacturer: nil,
        #      mandate: nil},
        #     {ps: 'American Issue Publishing Company',
        #      pubplace: nil, publisher: 'American Issue Publishing Company',
        #      pubdate: nil, manplace: nil, manufacturer: nil, mandate: nil},
        #     {ps: 'Chicago : New Voice Press, ©1898.',
        #      pubplace: 'Chicago', publisher: 'New Voice Press',
        #      pubdate: '©1898', manplace: nil, manufacturer: nil,
        #      mandate: nil},
        #     {ps: 'New York ; Berlin : Springer Verlag, 1977.',
        #      pubplace: 'New York|Berlin', publisher: 'Springer Verlag',
        #      pubdate: '1977', manplace: nil, manufacturer: nil,
        #      mandate: nil},
        #     {ps: 'Columbus : The League',
        #      pubplace: 'Columbus', publisher: 'The League',
        #      pubdate: nil, manplace: nil, manufacturer: nil,
        #      mandate: nil},
        #     {ps: '1908-1924.',
        #      pubplace: nil, publisher: nil, pubdate: '1908-1924',
        #      manplace: nil, manufacturer: nil, mandate: nil},
        #     {ps: 'Paris : Rue ; London : Press, 1955',
        #      pubplace: 'Paris|London', publisher: 'Rue|Press', pubdate: '1955',
        #      manplace: nil, manufacturer: nil, mandate: nil},
        #    # NOTE: Terminal period from publisher name removed, but we don't
        #    #   typically expect abbreviations on the end of this field
        #     {ps: 'Chicago, etc. : Time Inc.',
        #      pubplace: 'Chicago, etc.', publisher: 'Time Inc', pubdate: nil,
        #      manplace: nil, manufacturer: nil, mandate: nil},
        #    # NOTE: This is handled as best we can do without MARC subfields
        #     {ps: 'Paris : Impr. Vincent, 1798 [i.e. Bruxelles : Moens, 1883]',
        #      pubplace: 'Paris', publisher: 'Impr. Vincent',
        #      pubdate: '1798 [i.e. Bruxelles : Moens, 1883]',
        #      manplace: nil, manufacturer: nil, mandate: nil},
        #     {ps: 'London : Council, 1976 (Twickenham : CTD Printers, 1974)',
        #      pubplace: 'London', publisher: 'Council', pubdate: '1976',
        #      manplace: 'Twickenham' , manufacturer: 'CTD Printers',
        #      mandate: '1974'}
        #   ]
        #   xform = Split::PublicationStatement.new(source: :ps)
        #   result = input.map{ |row| xform.process(row) }
        #   expect(result).to eq(expected)
        # @example Overriding fieldnames
        #   input = [
        #     {ps: 'London : Council, 1976 (Twickenham : CTD Printers, 1974)'}
        #   ]
        #   expected = [
        #     {ps: 'London : Council, 1976 (Twickenham : CTD Printers, 1974)',
        #      pubplace: 'London', publisher: 'Council', pubdate: '1976',
        #      prtplace: 'Twickenham' , printer: 'CTD Printers',
        #      prtdate: '1974'}
        #   ]
        #   xform = Split::PublicationStatement.new(
        #     source: :ps,
        #     fieldname_overrides: {manplace: :prtplace, manufacturer: :printer,
        #       mandate: :prtdate}
        #   )
        #   result = input.map{ |row| xform.process(row) }
        #   expect(result).to eq(expected)
        #
        # @since 4.0.0
        class PublicationStatement
          DEFAULT_FIELDNAMES = %i[pubplace publisher pubdate
            manplace manufacturer mandate]

          # @param source [Symbol] field containing publication statement to
          #   split
          # @param fieldname_overrides [nil, Hash<Symbol=>Symbol>] with default
          #   field name to override as key, and new field name as value
          # @param delim [String] for joining multiple values in a given target
          #   field
          def initialize(source:,
            fieldname_overrides: nil,
            delim: Kiba::Extend.delim)
            @source = source
            @fieldnames = setup_fieldnames(fieldname_overrides)
            @delim = delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          # @return [Hash{ Symbol => String, nil }]
          def process(row)
            add_all_fields(row)
            val = row[source]
            return row if val.blank?

            extract_handler(row, scanner: initial_clean(val))
          end

          private

          attr_reader :source, :fieldnames, :delim

          def setup_fieldnames(overrides)
            base = DEFAULT_FIELDNAMES.map { |field| [field, field] }
              .to_h
            return base unless overrides

            base.merge(overrides)
          end

          def add_all_fields(row)
            fieldnames.values
              .each { |field| row[field] = nil }
            row
          end

          def initial_clean(val)
            StringScanner.new(
              val.strip
                .gsub(/  +/, " ")
                .delete_suffix(".")
            )
          end

          def extract_handler(row, scanner:)
            if scanner.exist?(/\(.+\)/) && manufacture?(scanner)
              man_handler(row, scanner: scanner)
            else
              extract_segmenter(row, scanner: scanner, type: :pub)
            end
          end

          def manufacture?(scanner)
            scanner.scan_until(/\(.*\)/)
            scanner.eos?
          end

          def man_handler(row, scanner:)
            pubscanner = StringScanner.new(scanner.pre_match.strip)
            manscanner = StringScanner.new(scanner.matched
                                           .sub(/\((.*)\)/, '\1'))
            manrow = extract_segmenter(row, scanner: manscanner, type: :man)
            extract_segmenter(manrow, scanner: pubscanner, type: :pub)
          end

          def extract_segmenter(row, scanner:, type:)
            if scanner.scan(/\d/)
              extract_date_only(row, scanner: scanner, type: type)
            elsif scanner.exist?(/[;:].*,[^,]+\d/)
              extract_date(row, scanner: scanner, type: type)
            elsif scanner.exist?(/[:;]/)
              extract_by_punct(row, scanner: scanner, type: type)
            elsif scanner.rest?
              extract_name(row, scanner: scanner, type: type)
            else
              row
            end
          end

          def extract_date_only(row, scanner:, type:)
            scanner.unscan
            dateval = {datefield(type) => scanner.rest}
            row.merge(dateval)
          end

          def extract_date(row, scanner:, type:)
            scanner.scan_until(/,[^,]+\d.*/)
            pre = scanner.pre_match
              .strip
            dateval = scanner.matched
              .delete_prefix(",")
              .strip
            daterow = row.merge({
              datefield(type) => dateval
            })

            extract_segmenter(daterow,
              scanner: StringScanner.new(pre),
              type: type)
          end

          def extract_by_punct(row, scanner:, type:)
            if scanner.bol?
              extract_place_from_start(row, scanner: scanner, type: type)
            elsif scanner.exist?(/[:;].*[:;]/)
              extract_intermediate_segment(row, scanner: scanner, type: type)
            elsif scanner.exist?(/[:;]/)
              extract_final_segment(row, scanner: scanner, type: type)
            end
          end

          def extract_name(row, scanner:, type:)
            nameval = {namefield(type) => scanner.rest}
            row.merge(nameval)
          end

          def extract_place_from_start(row, scanner:, type:)
            scanner.scan(/[^:;]+/)
            place = scanner.matched.strip
            placerow = add_value(row, field: placefield(type), value: place)

            extract_by_punct(placerow, scanner: scanner, type: type)
          end

          def extract_intermediate_segment(row, scanner:, type:)
            field = field_from_punct(
              punct: scanner.scan(/./), type: type
            )
            val = scanner.scan(/[^:;]+/)
            segrow = add_value(row, field: field, value: val.strip)

            extract_by_punct(segrow, scanner: scanner, type: type)
          end

          def extract_final_segment(row, scanner:, type:)
            field = field_from_punct(
              punct: scanner.scan(/./), type: type
            )
            add_value(row, field: field, value: scanner.rest.strip)
          end

          def field_from_punct(punct:, type:)
            meth = (punct == ":") ? :namefield : :placefield
            send(meth, type)
          end

          def add_value(row, field:, value:)
            existing = row[field]
            if existing.blank?
              row.merge({field => value})
            else
              joined = [existing, value].join(delim)
              row.merge({field => joined})
            end
          end

          def namefield(type)
            (type == :pub) ? fieldnames[:publisher] : fieldnames[:manufacturer]
          end

          def datefield(type)
            fieldnames["#{type}date".to_sym]
          end

          def placefield(type)
            fieldnames["#{type}place".to_sym]
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
