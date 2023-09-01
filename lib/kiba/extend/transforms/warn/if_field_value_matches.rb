# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      module Warn
        # @since 2.9.0.94
        #
        # Prints single warning to STDOUT if the value of the given field matches the given value in
        #   any rows
        #
        # Useful if you have skipped mapping/setting up transforms for certain values in an initial/staging
        #   data set, but need to ensure you will notice if later/production data includes new values
        #   that need attention.
        #
        # {https://github.com/lyrasis/kiba-tms/blob/8c0122ddb3e085bb7146df432cd1754e24e86c41/lib/kiba/tms/jobs/loans/prep.rb#L53-L55 Publicly available example of use in kiba-tms}
        #
        # Uses {Utils::FieldValueMatcher} to determine whether value matches. See that class' documentation
        #   for examples
        #
        # This transform warns if {Utils::FieldValueMatcher} finds a match.
        class IfFieldValueMatches
          include SingleWarnable

          # @param field [Symbol] whose value to match
          # @param match [String] expresses the match criteria
          # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
          # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
          #    split and the match is run against each resulting value
          # @param treat_as_null [nil, String] if given, the string will be converted to empty string for matching
          # @param casesensitive [Boolean] whether match cares about case
          # @param strip [Boolean] whether to strip leading/trailing spaces from values for matching
          # @param multimode [:any, :all, :allstrict] See {Utils::FieldValueMatcher}
          def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true,
            strip: true, multimode: :any)
            @field = field
            @match = match
            @matcher = Utils::FieldValueMatcher.new(
              field: field, match: match, matchmode: matchmode, delim: delim,
              treat_as_null: treat_as_null, casesensitive: casesensitive, strip: strip,
              multimode: multimode
            )
            setup_single_warning
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            return row unless single_warnings.empty?

            result = matcher.call(row)
            return row unless result

            msg = "One or more rows has #{field} value matching #{match}"
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
# rubocop:enable Layout/LineLength
