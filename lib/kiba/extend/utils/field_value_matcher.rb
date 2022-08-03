# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Callable service object returning true/false
      #
      # `matchmode: :plain` (the default) tests for a full match. You can test for partial matches with
      #   `matchmode: :regex`. Wrapping a regex match with `^` and `$` anchors will force a full match
      #   in regex match mode.
      class FieldValueMatcher
        # @param field [Symbol] whose value to match
        # @param match [String] expresses the match criteria 
        # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
        # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
        #    split and the match is run against each resulting value
        # @param treat_as_null [nil, String] if given, the string will be converted to empty string for matching
        # @param casesensitive [Boolean] whether match cares about case
        def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true)
          @field = field
          @delim = delim
          @casesensitive = casesensitive
          @matchmode = matchmode
          @nullval = treat_as_null
          @match = matchmode == :regexp ? create_regexp_match(match) : create_plain_match(match)
        end

        # @param row [Hash{Symbol => String}]
        def call(row)
          value = row[field]
          return false if value.nil?
          is_match?(prepare_value(value))
        end
        
        private

        attr_reader :field, :delim, :match, :matchmode, :nullval, :casesensitive
        
        def create_regexp_match(match)
          casesensitive ? Regexp.new(match) : Regexp.new(match, Regexp::IGNORECASE)
        end

        def create_plain_match(match)
          casesensitive ? match : match.downcase
        end

        def is_match?(vals)
          return vals.any?{ |val| val == match } if matchmode == :plain

          vals.any?{ |val| val.match?(match) }
        end
        
        def prepare_value(value)
          arrayed = delim ? value.split(delim, -1) : [value]
          nulled = nullval ? arrayed.map{ |val| val == nullval ? '' : val } : arrayed
          casesensitive ? nulled : nulled.map(&:downcase)
        end
      end
    end
  end
end
