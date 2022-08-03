# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Callable service object returning true/false
      #
      # `matchmode: :plain` (the default) tests for a full match. You can test for partial matches with
      #   `matchmode: :regex`. Wrapping a regex match with `^` and `$` anchors will force a full match
      #   in regex match mode.
      #
      # ## Examples
      #
      # ### With params: `field: :test, match: 'UNMAPPED'`
      #
      # ```
      # {foo: 'bar'} => false, # field not present, always false
      # {test: nil} => false, # nil field value, always false
      # {test: ''} => false,
      # {test: 'UNMAPPED'} => true,
      # {test: 'UNMAPPED '} => true, # values are stripped
      # {test: '  UNMAPPED '} => true, # values are stripped
      # {test: 'Unmapped'} => false
      # ```
      #
      # ### With params: `field: :test, match: 'UNMAPPED', strip: false`
      #
      # ```
      # {test: 'UNMAPPED'} => true,
      # {test: 'UNMAPPED '} => false, # values are not stripped
      # {test: '  UNMAPPED '} => false, # values are not stripped
      # {test: 'Unmapped'} => false
      # ```
      #
      # ### With params: `field: :test, match: 'UNMAPPED', casesensitive: false`
      #
      # ```
      # {test: 'UNMAPPED'} => true,
      # {test: 'Unmapped'} => true
      # ```
      #
      # ### With params: `field: :test, match: ''`
      #
      # ```
      # {foo: 'bar'} => false,
      # {test: nil} => false,
      # {test: ''} => true,
      # {test: ' '} => true, # values are stripped
      # {test: '    '} => true, # values are stripped
      # {test: 'UNMAPPED'} => false
      # ```
      #
      # ### With params: `field: :test, match: '', treat_as_null: '%NULL%'`
      #
      # ```
      # {foo: 'bar'} => false,
      # {test: nil} => false,
      # {test: ''} => true,
      # {test: 'UNMAPPED'} => false,
      # {test: '%NULL%'} => true, # gets converted to empty value prior to matching
      # {test: ' %NULL% '} => true # gets converted to empty value prior to matching
      # ```
      #
      # ### With params: `field: :test, match: '^$', treat_as_null: '%NULL%', matchmode: :regexp`
      #
      # ```
      # {foo: 'bar'} => false,
      # {test: nil} => false,
      # {test: ''} => true,
      # {test: 'UNMAPPED'} => false,
      # {test: '%NULL%'} => true
      # ```
      #
      # ### With params: `field: :test, match: 'Foo', delim: '|'`
      #
      # ```
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
      # ```
      #
      # ### With params: `field: :test, match: '^$', matchmode: :regex, delim: '|'`
      #
      # ```
      # {test: 'foo|'} => true,
      # {test: 'foo||foo'} => true,
      # {test: 'foo| |foo'} => true,
      # {test: '|foo'} => true,
      # {test: 'foo|%NULL%'} => false,
      # {test: 'foo|%NULL%|foo'} => false,
      # {test: 'foo| %NULL%|foo'} => false,
      # {test: '%NULL%|foo'} => false,
      # ```
      #
      # ### With params: `field: :test, match: '', delim: '|', treat_as_null: '%NULL%'`
      #
      # ```
      # {test: 'foo|%NULL%|bar'} => true,
      # {test: 'foo||bar'} => true,
      # {test: 'foo| %NULL% |bar'} => true,
      # {test: 'foo|  |bar'} => true
      # ```
      #
      # ### With params: `field: :test, match: '', delim: '|', treat_as_null: '%NULL%', strip: false`
      #
      # ```
      # {test: 'foo|%NULL%|bar'} => true,
      # {test: 'foo||bar'} => true,
      # {test: 'foo| %NULL% |bar'} => false,
      # {test: 'foo|  |bar'} => false
      # ```
      #
      # ### With params: `field: :test, match: '^fo+$', matchmode: :regex`
      #
      # ```
      # {test: 'food'} => false,
      # {test: 'foo'} => true,
      # {test: ' foo '} => true, # becasue stripped
      # {test: 'Food'} => false,
      # {test: 'Foo'} => false,
      # ```
      #
      # ### With params: `field: :test, match: '^fo+$', matchmode: :regex, delim: '|'`
      #
      # ```
      # {test: 'foo'} => true,
      # {test: 'foo|bar'} => true,
      # {test: 'Foo|bar'} => false,
      # {test: 'drink|food'} => false
      # ```
      #
      # ### With params: `field: :test, match: '^fo+', matchmode: :regex, delim: '|', casesensitive: false`
      #
      # ```
      # {test: 'foo'} => true,
      # {test: 'foo|bar'} => true,
      # {test: 'Foo|bar'} => true,
      # {test: 'drink|food'} => true
      # ```
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
        def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true,
                       strip: true)
          @field = field
          @delim = delim
          @casesensitive = casesensitive
          @matchmode = matchmode
          @nullval = treat_as_null
          @strip = strip
          @match = matchmode == :regexp ? create_regexp_match(match) : create_plain_match(match)
        end

        # @param row [Hash{Symbol => String}]
        def call(row)
          value = row[field]
          return false if value.nil?
          is_match?(prepare_value(value))
        end
        
        private

        attr_reader :field, :delim, :match, :matchmode, :nullval, :casesensitive, :strip
        
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
          stripped = strip ? arrayed.map(&:strip) : arrayed
          nulled = nullval ? stripped.map{ |val| val == nullval ? '' : val } : stripped
          casesensitive ? nulled : nulled.map(&:downcase)
        end
      end
    end
  end
end
