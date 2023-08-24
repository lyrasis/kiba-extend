# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Warn
        # @since 3.0.0
        #
        # Prints single warning to STDOUT if the value of the given field does not match match the given value
        #   in any rows
        #
        # Useful for getting notification that assumptions made during initial transformation development
        #   have changed in subsequent data.
        #
        # Uses {Utils::FieldValueMatcher} to determine whether value matches. See that class' documentation
        #   for examples/more details on parameters.
        #
        # This transform warns if {Utils::FieldValueMatcher} does not find a match
        class UnlessFieldValueMatches
          include SingleWarnable

          # @param field [Symbol] whose value to match
          # @param match [String] expresses the match criteria
          # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
          # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
          #   split and the match is run against each resulting value
          # @param treat_as_null [nil, String] if given, the string will be converted to empty string for matching
          # @param casesensitive [Boolean] whether match cares about case
          # @param strip [Boolean] whether to strip leading/trailing spaces from values for matching
          # @param multimode [:any, :all, :allstrict] See {Utils::FieldValueMatcher}
          def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true,
            strip: true, multimode: :all)
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
