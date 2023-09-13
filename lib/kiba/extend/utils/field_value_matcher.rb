# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Utils
      # Callable service object returning true/false
      #
      # If row does not contain the specified field at all, the result is always false.
      #
      # A `nil` value for the specified field will match `''` (matchmode: :plain) or `'^$'`
      #   (matchmode: :regexp)
      #
      # `matchmode: :plain` (the default) tests for a full match. You can test for partial matches with
      #   `matchmode: :regex`. Wrapping a regex match with `^` and `$` anchors will force a full match
      #   in regex match mode.
      #
      # ## Examples
      #
      # ### With params: `field: :test, match: 'UNMAPPED'`
      #
      # ~~~
      # {foo: 'bar'} => false, # field not present, always false
      # {test: nil} => false, # nil field value, always false
      # {test: ''} => false,
      # {test: 'UNMAPPED'} => true,
      # {test: 'UNMAPPED '} => true, # values are stripped
      # {test: '  UNMAPPED '} => true, # values are stripped
      # {test: 'Unmapped'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: 'UNMAPPED', strip: false`
      #
      # ~~~
      # {test: 'UNMAPPED'} => true,
      # {test: 'UNMAPPED '} => false, # values are not stripped
      # {test: '  UNMAPPED '} => false, # values are not stripped
      # {test: 'Unmapped'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: 'UNMAPPED', casesensitive: false`
      #
      # ~~~
      # {test: 'UNMAPPED'} => true,
      # {test: 'Unmapped'} => true
      # ~~~
      #
      # ### With params: `field: :test, match: ''`
      #
      # ~~~
      # {foo: 'bar'} => false,
      # {test: nil} => true,
      # {test: ''} => true,
      # {test: ' '} => true, # values are stripped
      # {test: '    '} => true, # values are stripped
      # {test: 'UNMAPPED'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: '', treat_as_null: '%NULL%'`
      #
      # ~~~
      # {foo: 'bar'} => false,
      # {test: nil} => true,
      # {test: ''} => true,
      # {test: 'UNMAPPED'} => false,
      # {test: '%NULL%'} => true, # gets converted to empty value prior to matching
      # {test: ' %NULL% '} => true # gets converted to empty value prior to matching
      # ~~~
      #
      # ### With params: `field: :test, match: '^$', treat_as_null: '%NULL%', matchmode: :regexp`
      #
      # ~~~
      # {foo: 'bar'} => false,
      # {test: nil} => true,
      # {test: ''} => true,
      # {test: 'UNMAPPED'} => false,
      # {test: '%NULL%'} => true
      # ~~~
      #
      # ### With params: `field: :test, match: 'Foo', delim: '|'`
      #
      # ~~~
      # {foo: 'Foo'} => false,
      # {test: nil} => false,
      # {test: ''} => false,
      # {test: 'Foo'} => true,
      # {test: 'foo'} => false,
      # {test: 'Foo|bar'} => true,
      # {test: 'baz|Foo'} => true,
      # {test: ' Foo|bar'} => true,
      # {test: 'baz| Foo '} => true,
      # {test: '|Foo'} => true,
      # {test: 'Foo|'} => true,
      # {test: 'foo|'} => false,
      # {test: 'bar|baz'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: '^$', matchmode: :regex, delim: '|'`
      #
      # ~~~
      # {test: 'foo|'} => true,
      # {test: 'foo||foo'} => true,
      # {test: 'foo| |foo'} => true,
      # {test: '|foo'} => true,
      # {test: 'foo|%NULL%'} => false,
      # {test: 'foo|%NULL%|foo'} => false,
      # {test: 'foo| %NULL%|foo'} => false,
      # {test: '%NULL%|foo'} => false,
      # ~~~
      #
      # ### With params: `field: :test, match: '', delim: '|', treat_as_null: '%NULL%'`
      #
      # ~~~
      # {test: 'foo|%NULL%|bar'} => true,
      # {test: 'foo||bar'} => true,
      # {test: 'foo| %NULL% |bar'} => true,
      # {test: 'foo|  |bar'} => true
      # ~~~
      #
      # ### With params: `field: :test, match: '', delim: '|', treat_as_null: '%NULL%', strip: false`
      #
      # ~~~
      # {test: 'foo|%NULL%|bar'} => true,
      # {test: 'foo||bar'} => true,
      # {test: 'foo| %NULL% |bar'} => false,
      # {test: 'foo|  |bar'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: '^fo+$', matchmode: :regex`
      #
      # ~~~
      # {test: 'food'} => false,
      # {test: 'foo'} => true,
      # {test: ' foo '} => true, # becasue stripped
      # {test: 'Food'} => false,
      # {test: 'Foo'} => false,
      # ~~~
      #
      # ### With params: `field: :test, match: '^fo+$', matchmode: :regex, delim: '|'`
      #
      # ~~~
      # {test: 'foo'} => true,
      # {test: 'foo|bar'} => true,
      # {test: 'Foo|bar'} => false,
      # {test: 'drink|food'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: '^fo+', matchmode: :regex, delim: '|', casesensitive: false`
      #
      # ~~~
      # {test: 'foo'} => true,
      # {test: 'foo|bar'} => true,
      # {test: 'Foo|bar'} => true,
      # {test: 'drink|food'} => true
      # ~~~
      #
      # ### With params: `field: :test, match: 'Foo', delim: '|', multimode: :all`
      #
      # ~~~
      # {foo: 'Foo'} => false,
      # {test: nil} => false,
      # {test: ''} => false,
      # {test: 'Foo'} => true,
      # {test: 'foo'} => false,
      # {test: 'Foo|Foo'} => true,
      # {test: 'Foo|bar'} => false,
      # {test: 'baz|Foo'} => false,
      # {test: ' Foo|bar'} => false,
      # {test: 'baz| Foo '} => false,
      # {test: '|Foo'} => true,
      # {test: 'Foo|'} => true,
      # {test: 'foo|'} => false,
      # {test: 'bar|baz'} => false
      # ~~~
      #
      # ### With params: `field: :test, match: 'Foo', delim: '|', multimode: :allstrict`
      #
      # ~~~
      # {foo: 'Foo'} => false,
      # {test: nil} => false,
      # {test: ''} => false,
      # {test: 'Foo'} => true,
      # {test: 'foo'} => false,
      # {test: 'Foo|Foo'} => true,
      # {test: 'Foo|bar'} => false,
      # {test: 'baz|Foo'} => false,
      # {test: ' Foo|bar'} => false,
      # {test: 'baz| Foo '} => false,
      # {test: '|Foo'} => false,
      # {test: 'Foo|'} => false,
      # {test: 'foo|'} => false,
      # {test: 'bar|baz'} => false
      # ~~~
      #
      class FieldValueMatcher
        # @param field [Symbol] whose value to match
        # @param match [String] expresses the match criteria
        # @param matchmode [:plain, :regex] If `:regex`, string is converted to a regular expression
        # @param delim [nil, String] if a String is given, triggers multivalue matching, where field value is
        #    split and the match is run against each resulting value
        # @param treat_as_null [nil, String] if given, the string will be converted to empty string for matching
        # @param casesensitive [Boolean] whether match cares about case
        # @param strip [Boolean] whether to strip individual values prior to matching
        # @param multimode [:any, :all, :allstrict] how a multivalue match is determined. If :any, result is true
        #   if any value matches. If :all, empty values are ignored and will return true if all populated values
        #   match. If :allstrict, empty values are not ignored and will return false if `match` value does not
        #   match them (since 3.0.0)
        def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true,
          strip: true, multimode: :any)
          @field = field
          @delim = delim
          @casesensitive = casesensitive
          @matchmode = matchmode
          @nullval = treat_as_null
          @strip = strip
          @match = (matchmode == :regexp) ? create_regexp_match(match) : create_plain_match(match)
          @multimode = multimode
        end

        # @param row [Hash{Symbol => String}]
        def call(row)
          return false unless row.key?(field)

          value = row[field]
          is_match?(prepare_value(value))
        end

        private

        attr_reader :field, :delim, :match, :matchmode, :nullval,
          :casesensitive, :strip, :multimode

        def create_regexp_match(match)
          casesensitive ? Regexp.new(match) : Regexp.new(match,
            Regexp::IGNORECASE)
        end

        def create_plain_match(match)
          casesensitive ? match : match.downcase
        end

        def is_match?(vals)
          (multimode == :any) ? is_match_any?(vals) : is_match_all?(vals)
        end

        def is_match_all?(vals)
          vals.reject! { |val| val.empty? } unless multimode == :allstrict
          return false if vals.empty?
          return vals.all? { |val| val == match } if matchmode == :plain

          vals.all? { |val| val.match?(match) }
        end

        def is_match_any?(vals)
          return vals.any? { |val| val == match } if matchmode == :plain

          vals.any? { |val| val.match?(match) }
        end

        def prepare_value(value)
          return [""] if value.blank?

          arrayed = delim ? value.split(delim, -1) : [value]
          compacted = arrayed.map { |val| val.nil? ? "" : val }
          stripped = strip ? compacted.map(&:strip) : compacted
          nulled = if nullval
            stripped.map do |val|
              (val == nullval) ? "" : val
            end
          else
            stripped
          end
          casesensitive ? nulled : nulled.map(&:downcase)
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
