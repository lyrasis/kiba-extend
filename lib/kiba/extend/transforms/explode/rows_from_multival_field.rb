# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Explode
        # Splits given field value on given delimiter. Original row is removed.
        #   One new row per split value is added. Value of split field is one of
        #   the split values per row. All other values in row are left the same
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Explode::RowsFromMultivalField,
        #   #   field: :r1
        #   xform = Explode::RowsFromMultivalField.new(
        #     field: :r1
        #   )
        #   input = [
        #     {r1: "a|b|c", r2: "c|d"},
        #     {r1: "", r2: "e|f"},
        #     {r1: nil, r2: "g|h"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {r1: "a", r2: "c|d"},
        #     {r1: "b", r2: "c|d"},
        #     {r1: "c", r2: "c|d"},
        #     {r1: "", r2: "e|f"},
        #     {r1: nil, r2: "g|h"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With delim given
        #   # Used in pipeline as:
        #   # transform Explode::RowsFromMultivalField,
        #   #   field: :r1, delim: "^^"
        #   xform = Explode::RowsFromMultivalField.new(
        #     field: :r1, delim: "^^"
        #   )
        #   input = [
        #     {r1: "a^^b", r2: "c^^d"},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {r1: "a", r2: "c^^d"},
        #     {r1: "b", r2: "c^^d"},
        #   ]
        #   expect(result).to eq(expected)
        class RowsFromMultivalField
          # @param field [Symbol] the field from which rows will be created
          # @param delim [String] used to split `field` value.
          #   `Kiba::Extend.delim` used if value not given
          def initialize(field:, delim: nil)
            @exploder = RowsFromGroupedMultivalFields.new(
              fields: field, delim: delim
            )
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            exploder.process(row){ |r| yield r }
          end

          private

          attr_reader :exploder
        end
      end
    end
  end
end
