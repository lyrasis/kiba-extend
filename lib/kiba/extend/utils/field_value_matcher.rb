# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Callable service object returning true/false
      class FieldValueMatcher
        def initialize(field:, match:, matchmode: :plain, delim: nil, treat_as_null: nil, casesensitive: true)
          @field = field
          @delim = delim
          @casesensitive = casesensitive
          @matchmode = matchmode
          @nullval = treat_as_null
          @match = matchmode == :regexp ? create_regexp_match(match) : create_plain_match(match)
        end

        def call(row)
          value = row[field]
          return false if value.nil?
          # pv = (prepare_value(value))
          # binding.pry
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
