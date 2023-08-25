# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Warn
        # @since 2.9.0.94
        #
        # rubocop:todo Layout/LineLength
        # Prints single warning to STDOUT if the value of the given field matches the given value in
        # rubocop:enable Layout/LineLength
        #   any rows
        #
        # rubocop:todo Layout/LineLength
        # Useful if you have skipped mapping/setting up transforms for certain values in an initial/staging
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   data set, but need to ensure you will notice if later/production data includes new values
        # rubocop:enable Layout/LineLength
        #   that need attention.
        #
        # {https://github.com/lyrasis/kiba-tms/blob/8c0122ddb3e085bb7146df432cd1754e24e86c41/lib/kiba/tms/jobs/loans/prep.rb#L53-L55 Publicly available example of use in kiba-tms}
        #
        # rubocop:todo Layout/LineLength
        # Uses {Utils::FieldValueMatcher} to determine whether value matches. See that class' documentation
        # rubocop:enable Layout/LineLength
        #   for examples
        #
        # This transform warns if {Utils::FieldValueMatcher} finds a match.
        class IfFieldValueMatches
          include SingleWarnable

          # @param field [Symbol] whose value to match
          # @param match [String] expresses the match criteria
          # rubocop:todo Layout/LineLength
          # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
          # rubocop:enable Layout/LineLength
          # rubocop:todo Layout/LineLength
          # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
          # rubocop:enable Layout/LineLength
          #    split and the match is run against each resulting value
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
            strip: true, multimode: :any)
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
