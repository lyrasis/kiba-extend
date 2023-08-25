# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Warn
        # @since 3.0.0
        #
        # rubocop:todo Layout/LineLength
        # Prints single warning to STDOUT if the value of the given field does not match match the given value
        # rubocop:enable Layout/LineLength
        #   in any rows
        #
        # rubocop:todo Layout/LineLength
        # Useful for getting notification that assumptions made during initial transformation development
        # rubocop:enable Layout/LineLength
        #   have changed in subsequent data.
        #
        # rubocop:todo Layout/LineLength
        # Uses {Utils::FieldValueMatcher} to determine whether value matches. See that class' documentation
        # rubocop:enable Layout/LineLength
        #   for examples/more details on parameters.
        #
        # rubocop:todo Layout/LineLength
        # This transform warns if {Utils::FieldValueMatcher} does not find a match
        # rubocop:enable Layout/LineLength
        class UnlessFieldValueMatches
          include SingleWarnable

          # @param field [Symbol] whose value to match
          # @param match [String] expresses the match criteria
          # rubocop:todo Layout/LineLength
          # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
          # rubocop:enable Layout/LineLength
          #   split and the match is run against each resulting value
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [nil, String] if given, the string will be converted to empty string for matching
          # rubocop:enable Layout/LineLength
          # @param casesensitive [Boolean] whether match cares about case
          # rubocop:todo Layout/LineLength
          # @param strip [Boolean] whether to strip leading/trailing spaces from values for matching
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param multimode [:any, :all, :allstrict] See {Utils::FieldValueMatcher}
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true,
            # rubocop:enable Layout/LineLength
            strip: true, multimode: :all)
            @field = field
            @match = match
            @matcher = Utils::FieldValueMatcher.new(
              field: field, match: match, matchmode: matchmode, delim: delim,
              # rubocop:todo Layout/LineLength
              treat_as_null: treat_as_null, casesensitive: casesensitive, strip: strip,
              # rubocop:enable Layout/LineLength
              multimode: multimode
            )
            setup_single_warning
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            return row unless single_warnings.empty?
            return row if row[field].blank?

            result = matcher.call(row)
            return row if result

            msg = "One or more rows has #{field} value not matching #{match}"
            add_single_warning(msg)
            row
          end

          private

          attr_reader :field, :match, :matcher
        end
      end
    end
  end
end
