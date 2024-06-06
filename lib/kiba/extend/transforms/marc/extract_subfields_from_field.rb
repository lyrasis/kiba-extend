# frozen_string_literal: true

require "marc"

module Kiba
  module Extend
    module Transforms
      module Marc
        # For each occurrence of given field tag, outputs a row with the
        #   following columns: marcid, fullfield, and one column per specified
        #   subfield. If there are more than one occurrnces of a subfield
        #   within a given field, the multiple values are separated by the
        #   delim value
        #
        # @example
        #   # =001  008000103-3
        #   # =260  \\$aLahore :$bZia-ul-Qurʾaan Publications,$c1996.
        #   rec = get_marc_record(index: 0)
        #   xform = Marc::ExtractSubfieldsFromField.new(
        #     tag: '260', subfields: %w[a b e f]
        #   )
        #   results = []
        #   xform.process(rec){ |row| results << row }
        #   expect(results.length).to eq(1)
        #   first = {
        #     :full260=>"260    $a Lahore : $b Zia-ul-Qurʾaan Publications, "\
        #       "$c 1996. ",
        #     :_260a=>"Lahore :", :_260b=>"Zia-ul-Qurʾaan Publications,",
        #     :_260e=>nil, :_260f=>nil, :marcid=>"008000103-3"
        #   }
        #   expect(results[0]).to eq(first)
        # @example
        #   # =001  008000411-3
        #   # =260  \\$aSan Jose, Calif. ;$aNew York, NY :$bH.M. Gousha
        #   #           Co.,$c[1986?]
        #   rec = get_marc_record(index: 3)
        #   xform = Marc::ExtractSubfieldsFromField.new(
        #     tag: '260', subfields: %w[a b e f]
        #   )
        #   results = []
        #   xform.process(rec){ |row| results << row }
        #   expect(results.length).to eq(1)
        #   first = {
        #     :full260=>"260    $a San Jose, Calif. ; $a New York, NY : $b "\
        #       "H.M. Gousha Co., $c [1986?] ",
        #     :_260a=>"San Jose, Calif. ;|New York, NY :",
        #     :_260b=>"H.M. Gousha Co.,",
        #     :_260e=>nil, :_260f=>nil, :marcid=>"008000411-3"
        #   }
        #   expect(results[0]).to eq(first)
        #
        # @since 4.0.0
        class ExtractSubfieldsFromField
          include FieldLinkable
          # @param tag [String] MARC tag from which to extract subfield values
          # @param subfields [Array<String>] subfield codes from which to
          #   extract values
          # @param delim [String] used when joining multiple values from
          #   recurring subfield
          def initialize(tag:, subfields:,
            id_target: Kiba::Extend::Marc.id_target_field,
            delim: Kiba::Extend.delim)
            @tag = tag
            @subfields = subfields
            @id_target = id_target
            @delim = delim
            @idextractor = Kiba::Extend::Utils::MarcIdExtractor.new
          end

          # @param record [MARC::Record]
          # @yieldparam row [Hash{ Symbol => String, nil }]
          def process(record)
            fields = select_fields(record, [tag])
              .reject { |fld| fld.codes.intersection(subfields).empty? }
            return nil if fields.empty?

            idhash = {id_target => idextractor.call(record)}

            prepare_rows(fields, idhash).each do |row|
              yield row
            end

            nil
          end

          private

          attr_reader :tag, :subfields, :id_target, :delim, :idextractor

          def prepare_rows(fields, idhash)
            fields.map { |fld| prepare_row(fld, idhash) }
          end

          def prepare_row(field, idhash)
            row = {"full#{tag}".to_sym => field.to_s}.merge(idhash)
            subfields.each do |code|
              row["_#{tag}#{code}".to_sym] = sf_val(field, code)
            end
            row.transform_values { |val| val.blank? ? nil : val }
          end

          def sf_val(field, code)
            field.subfields
              .select { |sf| sf.code == code }
              .map { |sf| sf.value }
              .join(delim)
          end
        end
      end
    end
  end
end
