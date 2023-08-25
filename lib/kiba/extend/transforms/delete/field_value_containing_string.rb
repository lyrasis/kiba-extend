# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # rubocop:todo Layout/LineLength
        # Deletes full field value of all given fields that contain the given string. You can control
        # rubocop:enable Layout/LineLength
        #   whether match is case sensitive or not.
        #
        # rubocop:todo Layout/LineLength
        # To be clear, **contain = a partial match**. Use {FieldValueMatchingRegexp} with anchors to
        # rubocop:enable Layout/LineLength
        #   trigger deletion via a full match.
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
        # rubocop:todo Layout/LineLength
        # transform Delete::FieldValueContainingString, fields: %i[a b], match: 'xxxx'
        # rubocop:enable Layout/LineLength
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
        # | y thing | xXxXxXy |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Delete::FieldValueContainingString, fields: :b, match: 'xxxx', casesensitive: false
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # | a       | b   |
        # |---------+-----|
        # | y thing | nil |
        # ```
        #
        class FieldValueContainingString
          # @param fields [Array<Symbol>,Symbol] field(s) to delete from
          # @param match [String] value to match
          # @param casesensitive [Boolean] match mode
          def initialize(fields:, match:, casesensitive: true)
            @fields = [fields].flatten
            @match = casesensitive ? match : match.downcase
            @casesensitive = casesensitive
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fields.each do |field|
              exval = row.fetch(field)
              next if exval.blank?

              prepped = casesensitive ? exval : exval.downcase
              row[field] = nil if prepped[match]
            end

            row
          end

          private

          attr_reader :fields, :match, :casesensitive
        end
      end
    end
  end
end
