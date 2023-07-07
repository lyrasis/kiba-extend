# frozen_string_literal: true

require "set"

module Kiba
  module Extend
    module Transforms
      module Helpers
        # Returns true/false indicating whether given value matches any
        #   given or added patterns. Used on a list of names and name-like
        #   values, **where standard inverted name entry patterns are
        #   followed**, this works ok. It will not work at all on directly-
        #   entered names. Used on a list of subject like terms or
        #   on freetext, be wary of false positives (though the patterns and
        #   the duplicative anchoring matching tries to avoid matching
        #   subject-like terms
        #
        # The default name list provided is all unique first names from the data
        #   set at https://www.ssa.gov/OACT/babynames/limits.html which have
        #   been on more than 100 Social Security card applications from
        #   1880-2022. So there is a definite U.S. bias.
        class PersonNameChecker
          class << self
            def call(
              value:,
              added_patterns: [],
              family_is_person: false
            )
              self.new(
                added_patterns: added_patterns,
                family_is_person: family_is_person
              ).call(value)
            end
          end

          # rubocop:disable Layout/LineLength
          DEFAULT_PATTERNS = [
          ]

          ANTIPATTERNS = [
            /^\d/,
            /^\w+\.?$/
          ]

          FAMILY_PATTERNS = [
            / famil(ies|y)/i
          ]
          # rubocop:enable Layout/LineLength

          # @param added_patterns [Array<Regexp>] non-standard regexp to check
          #   against. Best practice is to add these to this helper via a pull
          #   request if you think they generally indicate organization-ness
          # @param family_is_person [Boolean] whether names with terms
          #   indicating family-ness are treated as persons (false for
          #   CollectionSpace, potentially true for other applications)
          # @param name_lists [Array<String>] paths to file(s) containing known
          #   given name Strings
          # @param mode [:strict, :lenient] `:strict` requires the given name
          #   to be in an expected position (as per the `order` parameter) for
          #   the value to be flagged as a name. `:lenient` will flag the value
          #   as a name if any words in the value match values in the
          #   `name_lists`
          # @param order [:direct, :inverted] expected order of names. Has no
          #   effect if `mode=:lenient`
          def initialize(added_patterns: [], family_is_person: false,
                         name_lists: [File.join(Kiba::Extend.ke_dir, "data",
                                                "us_names_1880-2022_gt100.txt")
                                     ],
                         mode: :strict, order: :inverted)
            base = DEFAULT_PATTERNS + added_patterns
            @patterns = family_is_person ? base + FAMILY_PATTERNS : base
            anti = ANTIPATTERNS
            @antipatterns = family_is_person ? anti : anti + FAMILY_PATTERNS
            @names = set_up_names(name_lists)
            @mode = mode
            @order = order
          end

          # @param value [String]
          # @return [true] if `value` matches a person pattern
          # @return [false] otherwise
          def call(value)
            return false if value.blank?
            return false if antipatterns.any? do |pattern|
              value.match?(pattern)
            end
            return true if patterns.any? do |pattern|
              value.match?(pattern)
            end

            mode == :lenient ? lenient_check(value) : strict_check(value)
          end

          private

          attr_reader :patterns, :antipatterns, :names, :mode, :order

          def set_up_names(files)
            files.map{ |file| File.readlines(file, chomp: true) }
              .flatten
              .to_set
          end

          def lenient_check(value)
            value.split(" ")
              .map{ |segment| segment.gsub(/\W/, "") }
              .reject{ |segment| segment.length == 1 }
              .any?{ |segment| names.member?(segment) }
          end

          def strict_check(value)
            order == :direct ? direct_check(value) : inverted_check(value)
          end

          def direct_check(value)
            parts = value.split(" ")
            return false if parts.length == 1

            nonsurname = parts[0..-2]
              .join(" ")
            return true if start_with_title?(nonsurname)
            return true if is_initials?(nonsurname)

            lenient_check(nonsurname)
          end

          def inverted_check(value)
            parts = value.split(", ")
            return false if parts.length == 1

            nonsurname = parts[1..-1]
              .join(", ")
            return true if start_with_title?(nonsurname)
            return true if is_initials?(nonsurname)

            lenient_check(nonsurname)
          end

          def start_with_title?(str)
            str.match?(/^(?:Dr|Miss|Mrs?|Ms|Prof|Rev)\b/)
          end

          def is_initials?(str)
            str.match?(/^(?:[A-Z]\.? ?)+$/)
          end
        end
      end
    end
  end
end
