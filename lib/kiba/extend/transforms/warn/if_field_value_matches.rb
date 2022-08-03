# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Warn
        # @since 2.9.0.94
        #
        # Prints single warning to STDOUT if the value of the given field matches the given value in
        #   any rows
        #
        # Uses {Utils::FieldValueMatcher} to determine whether value matches. See that class' documentation
        #   for examples 
        class IfFieldValueMatches
          include SingleWarnable
          
        # @param field [Symbol] whose value to match
        # @param match [String] expresses the match criteria 
        # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
        # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
        #    split and the match is run against each resulting value
        # @param treat_as_null [nil, String] if given, the string will be converted to empty string for matching
        # @param casesensitive [Boolean] whether match cares about case
          def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true,
                        strip: true)
            @field = field
            @match = match
            @matcher = Utils::FieldValueMatcher.new(
              field: field, match: match, matchmode: matchmode, delim: delim,
              treat_as_null: treat_as_null, casesensitive: casesensitive, strip: strip
            )
            setup_single_warning
          end
          
          # @param row [Hash{ Symbol => String }]
          def process(row)
            return row unless single_warnings.empty?

            result = matcher.call(row)
            return row unless result
            
            msg = "#{Kiba::Extend.warning_label}: One or more rows has #{field} value matching #{match}"
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
