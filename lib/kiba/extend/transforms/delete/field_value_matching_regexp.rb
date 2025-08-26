# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # Deletes full field value of all given fields that match the given
        #   regular expression pattern. You can control whether the regexp is
        #   case sensitive or not.
        #
        # @example Match as string, case sensitive
        #   # Used in pipeline as:
        #   # transform Delete::FieldValueMatchingRegexp,
        #   #   fields: %i[a b z],
        #   #   match: "xx+"
        #   xform = Delete::FieldValueMatchingRegexp.new(
        #     fields: %i[a b z], match: "xx+"
        #   )
        #   input = [
        #     {a: "xxxx a thing", b: "foo"},
        #     {a: "thing xxxx 123", b: "bar"},
        #     {a: "x thing", b: "xxxx"},
        #     {a: "y thing", b: "xXxX"},
        #     {a: "xxxxxxx thing", b: "baz"},
        #     {a: "", b: nil}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: nil, b: "foo"},
        #     {a: nil, b: "bar"},
        #     {a: "x thing", b: nil},
        #     {a: "y thing", b: "xXxX"},
        #     {a: nil, b: "baz"},
        #     {a: "", b: nil}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Match as anchored string, case insensitive
        #   # Used in pipeline as:
        #   # transform Delete::FieldValueMatchingRegexp,
        #   #   fields: %i[a b],
        #   #   match: "^xx+", casesensitive: false
        #   xform = Delete::FieldValueMatchingRegexp.new(
        #     fields: %i[a b], match: "^xx+", casesensitive: false
        #   )
        #   input = [
        #     {a: "an xxxx", b: "xXxXxXy"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {a: "an xxxx", b: nil}
        #   ]
        #   expect(result).to eq(expected)
        class FieldValueMatchingRegexp
          # @param fields [Array<Symbol>,Symbol] field(s) to delete from
          # @param match [String] value to match. Is converted to a regular
          #   expression pattern via `Regexp.new(match)`
          # @param casesensitive [Boolean] match mode
          def initialize(fields:, match:, casesensitive: true)
            @fields = [fields].flatten
            @match = casesensitive ? Regexp.new(match) : Regexp.new(match,
              Regexp::IGNORECASE)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fields.each do |field|
              val = row.fetch(field, nil)
              next if val.blank?

              row[field] = nil if val.match?(match)
            end

            row
          end

          private

          attr_reader :fields, :match
        end
      end
    end
  end
end
