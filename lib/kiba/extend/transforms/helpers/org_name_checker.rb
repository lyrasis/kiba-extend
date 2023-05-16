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

          # rubocop:disable Layout/LineLength
          DEFAULT_PATTERNS = [
              / LLC/i,
              / co$/i,
              / co\./i,
              / corp\.$/i,
              / dept\.?$/i,
              /dept\./i,
              / inc$/i,
              /inc\./i,
              /^\w+ & \w+$/,
              /^(\w+,? )+& \w+$/,
              /'s$/,
              # military
              /^(artillery|brigade|infantry|regiment) /i,
              / (artillery|brigade|infantry|regiment) /i,
              / (artillery|brigade|infantry|regiment)$/i,
              # organizational units
              /(inter|multi)?national/i,
              /^(administration|assembly|bureau|commission|committee|council|department|division|federation|office) /i,
              / (administration|assembly|bureau|commission|committee|council|department|division|federation|office) /i,
              / (administration|assembly|bureau|commission|committee|council|department|division|federation|office)$/i,
              # education
              /^(academy|college|institute|program|university|school) /i,
              / (academy|college|institute|program|university|school) /i,
              / (academy|college|institute|program|university|school)$/i,
              / (elementary|middle|primary|high)$/i,
              # health-related
              /^(hospital|nursing home|pharmacy) /i,
              / (hospital|nursing home|pharmacy) /i,
              / (hospital|nursing home|pharmacy)$/i,
              # governmental
              /^(agency|court of|general assembly|senate|tribe) /i,
              / (agency|court of|general assembly|senate|tribe)\.? /i,
              / (agency|court of|general assembly|senate|tribe)$/i,
              # non-profity terms
              /^(alliance|board of|foundation|program|task ?force) /i,
              / (alliance|board of|foundation|program|task ?force) /i,
              / (alliance|board of|foundation|program|task ?force)$/i,
              / (network|project|services?)$/i,
              # corporate/company name terms
              /^(company|consultant(s|)|corporation|group|incorporated|service) /i,
              / (company|consultant(s|)|corporation|group|incorporated|service) /i,
              / (company|consultant(s|)|corporation|group|incorporated|service)$/i,
              /\.com$/,
              # glam/cultural institutions
              /^(band|centers?|ensemble|gallery|library|museum|observatory|orchestra|studio|theat(er|re)) /i,
              / (band|centers?|ensemble|gallery|library|museum|observatory|orchestra|studio|theat(er|re)) /i,
              / (band|centers?|ensemble|gallery|library|museum|observatory|orchestra|studio|theat(er|re))$/i,
              # clubs/groups
              /^(association|choir|club|fraternity|friends of the|legion|league|society|sorority|team) /i,
              / (association|choir|club|fraternity|friends of the|legion|league|society|sorority|team) /i,
              / (association|choir|club|fraternity|friends of the|legion|league|society|sorority|team)$/i,
              # events
              /^(games|olympics) /i,
              / (games|olympics) /i,
              / (games|olympics)$/i,
              # transportation
              /^(airport|depot|rail(road|way)) /i,
              / (airport|depot|rail(road|way)) /i,
              / (airport|depot|rail(road|way))$/i,
              # food and drink
              /^(brewer(ies|y)|cafe|farm|grocer(ies|y)|restaurant|saloon|tavern) /i,
              / (brewer(ies|y)|cafe|farm|grocer(ies|y)|restaurant|saloon|tavern) /i,
              / (brewer(ies|y)|cafe|farm|grocer(ies|y)|restaurant|saloon|tavern)$/i,
              # areas/types of business
              /publish/i,
              /^(auto(motive|)|hotel(s)|inn|insurance|plumb(ers|ing)|roofing|shop|store) /i,
              / (auto(motive|)|hotel(s)|inn|insurance|plumb(ers|ing)|roofing|shop|store) /i,
              / (auto(motive|)|hotel(s)|inn|insurance|plumb(ers|ing)|roofing|shop|store)$/i,
            ]

          FAMILY_PATTERNS = [
            / famil(ies|y)/i
          ]
          # rubocop:enable Layout/LineLength

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
            return false if value.blank?
            return true if patterns.any? { |pattern| value.match?(pattern) }

            false
          end

          private

          attr_reader :patterns
        end
      end
    end
  end
end
