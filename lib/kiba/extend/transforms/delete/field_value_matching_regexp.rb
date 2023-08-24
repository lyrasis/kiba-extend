# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # Deletes full field value of all given fields that match the given regular expression pattern.
        #   You can control whether the regexp is case sensitive or not
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | a              | b    |
        # |----------------+------|
        # | xxxx a thing   | foo  |
        # | thing xxxx 123 | bar  |
        # | x thing        | xxxx |
        # | y thing        | xXxX |
        # | xxxxxxx thing  | baz  |
        # |                | nil  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::FieldValueMatchingRegexp, fields: %i[a b], match: 'xx+'
        # ```
        #
        # Results in:
        #
        # ```
        # | a       | b    |
        # |---------+------|
        # | nil     | foo  |
        # | nil     | bar  |
        # | x thing | nil  |
        # | y thing | xXxX |
        # | nil     | baz  |
        # |         | nil  |
        # ```
        #
        # Input table:
        #
        # ```
        # | a       | b       |
        # |---------+---------|
        # | an xxxx | xXxXxXy |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::FieldValueMatchingRegexp, fields: %i[a b], match: '^xx+', casesensitive: false
        # ```
        #
        # Results in:
        #
        # ```
        # | a       | b   |
        # |---------+-----|
        # | an xxxx | nil |
        # ```
        #
        class FieldValueMatchingRegexp
          # @param fields [Array<Symbol>,Symbol] field(s) to delete from
          # @param match [String] value to match. Is converted to a regular expression pattern via `Regexp.new(match)`
          # @param casesensitive [Boolean] match mode
          def initialize(fields:, match:, casesensitive: true)
            @fields = [fields].flatten
            @match = casesensitive ? Regexp.new(match) : Regexp.new(match,
              Regexp::IGNORECASE)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fields.each do |field|
              val = row.fetch(field)
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
