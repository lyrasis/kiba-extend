# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Fingerprint
        # With a lookup table derived from a job using {FlagChanged}, and a
        #   source table having a fingerprint field which can be used as a
        #   keycolumn for the lookup table, apply corrections from the lookup
        #   table to the source table. If multiple matching correction rows are
        #   found in the lookup table, they will be applied in the order they
        #   are returned from the lookup table.
        #
        # @note If you are giving custom target fields via the `fieldmap`
        #   parameter, or your source table does not already contain the target
        #   fields, you will need to run the {Clean::EnsureConsistentFields}
        #   transform after running this, and before writing output.
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Fingerprint::MergeCorrected,
        #   #   keycolumn: :fp,
        #   #   lookup: lookup,
        #   #   todofield: :corrected
        #   lookup = {
        #     "1"=>[{key: "1", a: "apps", b: nil, corrected: "a|b"}],
        #     "2"=>[{key: "2", a: "apple", b: "bee", corrected: "b"},
        #           {key: "2", a: "apples", b: "bee", corrected: "a"}],
        #     "3"=>[{key: "3", a: "apple", b: "bees", corrected: nil}]
        #   }
        #   xform = Fingerprint::MergeCorrected.new(
        #     keycolumn: :fp,
        #     lookup: lookup,
        #     todofield: :corrected
        #   )
        #   input = [
        #     {fp: "1", a: 'ant', b: 'bear'},
        #     {fp: "2", a: 'ant', b: 'bear'},
        #     {fp: "3", a: 'ant', b: 'bear'},
        #     {fp: "4", a: 'ant', b: 'bear'},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {fp: "1", a: 'apps', b: nil},
        #     {fp: "2", a: 'apples', b: 'bee'},
        #     {fp: "3", a: 'ant', b: 'bear'},
        #     {fp: "4", a: 'ant', b: 'bear'},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With tag_affected_in
        #   # Used in pipeline as:
        #   # transform Fingerprint::MergeCorrected,
        #   #   keycolumn: :fp,
        #   #   lookup: lookup,
        #   #   todofield: :corrected,
        #   #   tag_affected_in: :corr
        #   lookup = {
        #     "1"=>[{key: "1", a: "apps", b: nil, corrected: "a|b"}],
        #     "2"=>[{key: "2", a: "apple", b: "bee", corrected: "b"},
        #           {key: "2", a: "apples", b: "bee", corrected: "a"}],
        #     "3"=>[{key: "3", a: "apple", b: "bees", corrected: nil}]
        #   }
        #   xform = Fingerprint::MergeCorrected.new(
        #     keycolumn: :fp,
        #     lookup: lookup,
        #     todofield: :corrected,
        #     tag_affected_in: :corr
        #   )
        #   input = [
        #     {fp: "1", a: 'ant', b: 'bear'},
        #     {fp: "2", a: 'ant', b: 'bear'},
        #     {fp: "3", a: 'ant', b: 'bear'},
        #     {fp: "4", a: 'ant', b: 'bear'},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {fp: "1", a: 'apps', b: nil, corr: "y"},
        #     {fp: "2", a: 'apples', b: 'bee', corr: "y"},
        #     {fp: "3", a: 'ant', b: 'bear', corr: "n"},
        #     {fp: "4", a: 'ant', b: 'bear', corr: "n"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With fieldmap and tag_affected_in
        #   # Used in pipeline as:
        #   # transform Fingerprint::MergeCorrected,
        #   #   keycolumn: :fp,
        #   #   lookup: lookup,
        #   #   todofield: :corrected,
        #   #   fieldmap: {a: :ac, b: :bc},
        #   #   tag_affected_in: :corr
        #   lookup = {
        #     "1"=>[{key: "1", a: "apps", b: nil, corrected: "a|b"}],
        #     "2"=>[{key: "2", a: "apple", b: "bee", corrected: "b"}],
        #     "3"=>[{key: "3", a: "apple", b: "bees", corrected: nil}]
        #   }
        #   xform = Fingerprint::MergeCorrected.new(
        #     keycolumn: :fp,
        #     lookup: lookup,
        #     todofield: :corrected,
        #     fieldmap: {a: :ac, b: :bc},
        #     tag_affected_in: :corr
        #   )
        #   input = [
        #     {fp: "1", a: 'ant', b: 'bear'},
        #     {fp: "2", a: 'ant', b: 'bear'},
        #     {fp: "3", a: 'ant', b: 'bear'},
        #     {fp: "4", a: 'ant', b: 'bear'},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {fp: "1", a: 'ant', b: 'bear', ac: "apps", bc: nil, corr: "y"},
        #     {fp: "2", a: 'ant', b: 'bear', bc: "bee", corr: "y"},
        #     {fp: "3", a: 'ant', b: 'bear', corr: "n"},
        #     {fp: "4", a: 'ant', b: 'bear', corr: "n"},
        #   ]
        #   expect(result).to eq(expected)
        class MergeCorrected
          # @param keycolumn [Symbol] the name of the field containing
          #   fingerprint values in data into which corrections will be
          #   merged
          # @param lookup [Hash] created by {Utils::Lookup.csv_to_hash} or
          #   any method producing a Hash with the same structure
          # @param todofield [Symbol] name of field (in lookup table) containing
          #   list of fields from which corrections should be merged in. This
          #   would the `target` parameter passed to the {FlagChanged} transform
          # @param fieldmap [Hash] where key is name of corrected field in
          #   lookup table, and value is the name of the field in source table
          #   the corrected value should be mapped to. If corrected :publisher
          #   should merge into source :publisher, then you do not need to
          #   include :publisher as a key in the `fieldmap`.
          # @param tag_affected_in [nil, Symbol] If a Symbol is given, a new
          #   field is added indicating (y/n) whether corrections were merged
          #   into each row. If `nil`, no indicator column is added
          def initialize(keycolumn:, lookup:, todofield:, fieldmap: {},
            tag_affected_in: nil)
            @keycolumn = keycolumn
            @lookup = lookup
            @todofield = todofield
            @fieldmap = fieldmap
            @tag_affected_in = tag_affected_in
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            row[tag_affected_in] = "n" if tag_affected_in
            correction_steps = get_correction_steps(row)
            return row if correction_steps.blank?

            do_correction_steps(row, correction_steps)
            row[tag_affected_in] = "y" if tag_affected_in
            row
          end

          private

          attr_reader :keycolumn, :lookup, :todofield, :fieldmap,
            :tag_affected_in

          def get_correction_steps(row)
            lookup_rows = lookup[row[keycolumn]]
            return {} if lookup_rows.blank?

            lookup_rows.reject { |lkrow| lkrow[todofield].blank? }
          end

          def do_correction_steps(row, correction_steps)
            correction_steps.each do |corrections|
              do_corrections(row, corrections)
            end
          end

          def do_corrections(row, corrections)
            corrections[todofield].split(Kiba::Extend.delim)
              .map(&:to_sym)
              .each do |field|
                target = get_target(field)
                row[target] = corrections[field]
              end
          end

          def get_target(field)
            target = fieldmap[field]
            return field unless target

            target
          end
        end
      end
    end
  end
end
