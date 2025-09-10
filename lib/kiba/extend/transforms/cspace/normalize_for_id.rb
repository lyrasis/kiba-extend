# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Cspace
        # @note This class makes use of {Utils::StringNormalizer} with
        #   `mode: :cspaceid`. See that class for more details and fuller
        #   tests of string normalization
        #
        # @see Kiba::Extend::Transforms::Cspace Using Cspace transforms when
        #   your project defines a Cspace module
        #
        # Normalizes a string value---typically a value that will become a
        #   CSpace authority `termdisplayname` value---using the same (or as
        #   close as possible to the same) algorithm as the CSpace application
        #   uses to generate the `shortid` field in authority records.
        #
        # This is useful for identifying values that are not exact string
        #   matches, but that CSpace may see/treat as duplicates under the hood
        #   where it uses the `shortid` (which is embedded in refName URNs).
        #   In preparing data for CSpace migrations, this can prevent creation
        #   of terms that cause problems during ingest, or that will later
        #   cause warnings/errors if you try to load Objects or Procedures
        #   containing those terms.
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Cspace::NormalizeForID,
        #   #   source: :place,
        #   #   target: :norm
        #   xform = Cspace::NormalizeForID.new(
        #     source: :place,
        #     target: :norm
        #   )
        #   input = [
        #     {place: 'Table, café'},
        #     {place: 'Oświęcim (Poland)|Iași, Romania'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {place: 'Table, café', norm: 'tablecafe'},
        #     {place: 'Oświęcim (Poland)|Iași, Romania',
        #      norm: 'oswiecimpolandiasiromania'}
        #   ]
        #   expect(result).to eq(expected)
        # @example With delim
        #   # Used in pipeline as:
        #   # transform Cspace::NormalizeForID,
        #   #   source: :place,
        #   #   target: :norm,
        #   #   delim: '|'
        #   xform = Cspace::NormalizeForID.new(
        #     source: :place,
        #     target: :norm,
        #     delim: '|'
        #   )
        #   input = [
        #     {place: 'Table, café'},
        #     {place: 'Oświęcim (Poland)|Iași, Romania'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {place: 'Table, café', norm: 'tablecafe'},
        #     {place: 'Oświęcim (Poland)|Iași, Romania',
        #      norm: 'oswiecimpoland|iasiromania'}
        #   ]
        #   expect(result).to eq(expected)
        class NormalizeForID
          # @param source [Symbol] field whose value will be normalized
          # @param target [Symbol] field to populate with normalized value
          # @param delim [nil, String] if given triggers treatment as
          #   multivalued, and is used to split/join string values
          def initialize(source:, target:, delim: nil)
            @source = source
            @target = target
            @delim = delim
            @normalizer = Kiba::Extend::Utils::StringNormalizer.new(
              mode: :cspaceid
            )
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            row[target] = nil
            val = row.fetch(source, nil)
            return row if val.blank?

            row[target] = values(val).map { |val| normalize(val) }.join(delim)
            row
          end

          private

          attr_reader :source, :target, :delim, :normalizer

          def normalize(val)
            normalizer.call(val)
          end

          def values(val)
            return [val] unless delim

            val.split(delim)
          end
        end
      end
    end
  end
end
