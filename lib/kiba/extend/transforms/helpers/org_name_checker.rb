# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Helpers
        # Returns true/false indicating whether given value matches any
        #   given or added patterns. Used on a list of names and name-like
        #   values, this works ok. Used on a list of subject like terms or
        #   on freetext, be wary of false positives (though the patterns and
        #   the duplicative anchoring matching tries to avoid matching
        #   subject-like terms
        class OrgNameChecker
          class << self
            def call(
              value:,
              added_patterns: [],
              family_is_org: false
            )
              self.new(
                added_patterns: added_patterns,
                family_is_org: family_is_org
              ).call(value)
            end
          end

          TERMS = <<~LIST
            (?:
            # business domains or types
            auto(motive|)|hotels?|inn|insurance|plumb(ers|ing)|roofing|shop|
            store|
            # clubs and groups
            association|club|fraternity|friends of the|legion|league|
            society|sorority|team|
            # corporate or company name terms
            company|consultant(s|)|corporation|group|incorporated|service|
            # education
            academy|college|institute|program|university|school|
            # events
            games|olympics|
            # food and drink
            brewer(ies|y)|cafe|farm|grocer(ies|y)|restaurant|saloon|tavern|
            # glam or cultural institutions
            band|centers?|choir|ensemble|gallery|library|museum|observatory|
            orchestra|studio|theat(er|re)|
            # governmental
            agency|court of|general assembly|senate|tribe|
            # health-related
            hospital|nursing home|pharmacy|
            # military
            artillery|brigade|infantry|regiment|
            # non-profity terms
            alliance|board of|foundation|program|task ?force|
            # organizational units
            administration|assembly|bureau|commission|committee|council|
            department|division|federation|office|
            # transportation
            airport|depot|rail(road|way)
            )
          LIST

          DEFAULT_PATTERNS = [
              / LLC/i,
              / co$/i,
              / corp$/i,
              /\bdept$/i,
              /\bdept\./i,
              /\binc$/i,
              /\binc\./i,
              /^\w+ (?:&|and) \w+$/,
              /^(\w+,? )+(?:&|and) \w+$/,
              /'s$/,
              /\b(inter|multi)?national\b/i,
              / (network|project|services?)$/i,
              /\.com$/,
              /publish/i,
              # term at beginning
              /^#{TERMS}\b.+/ix,
              # term between other terms
              /.+\b#{TERMS}\b.+/ix,
              # term at end
              /.+\b#{TERMS}$/ix
            ]

          FAMILY_PATTERNS = [
            / famil(ies|y)/i
          ]

          # @param added_patterns [Array<Regexp>] non-standard regexp to check
          #   against. Best practice is to add these to this helper via a pull
          #   request if you think they generally indicate organization-ness
          # @param family_is_org [Boolean] whether names with terms indicating
          #   family-ness are treated as organizations (yes for CollectionSpace,
          #   no for applications that have a Family name type)
          def initialize(added_patterns: [], family_is_org: false)
            base = DEFAULT_PATTERNS + added_patterns
            @patterns = family_is_org ? base + FAMILY_PATTERNS : base
          end

          # @param value [String]
          # @return [true] if `value` matches an org pattern
          # @return [false] otherwise
          def call(value)
            testval = value.sub(/\. *$/, "")
            return false if testval.blank?
            return true if patterns.any? { |pattern| testval.match?(pattern) }

            false
          end

          private

          attr_reader :patterns
        end
      end
    end
  end
end
