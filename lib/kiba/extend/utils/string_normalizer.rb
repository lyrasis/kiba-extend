# frozen_string_literal: true

module Kiba
  module Extend
    module Utils
      # Normalizes the given string according to the given parameters.
      #
      # Can be used two ways. Preferred method when using in a transform or
      #   other context when the same normalization settings will be used to
      #   normalize many strings:
      #
      # ~~~
      #   # First initialize an instance of the class as an instance variable in
      #   #   your context
      #   @normalizer = Kiba::Extend::Utils::StringNormalizer.new(
      #     xforms: [:blank]
      #   )
      #
      #   # for the repetitive part:
      #   vals.each{ |val| @normalizer.call(val) }
      # ~~~
      #
      # For one-off usage, testing normalization logic, or where the
      #   normalization settings vary per normalized value, you can do:
      #
      # ~~~
      # Kiba::Extend::Utils::StringNormalizer.call(
      #   xforms: [:blank], str: 'Card table'
      # )
      #   => 'Cardtable'
      # ~~~
      #
      # The second way is much less performant, as it initializes a new instance
      #   of the class every time it is called.
      #
      # @example Downcase only
      #   util = Kiba::Extend::Utils::StringNormalizer.new(xforms: [:lower])
      #   input = [
      #     'Oświęcim (Poland)',
      #     'Oswiecim, Poland',
      #     'Iași, Romania',
      #     'Iasi, Romania',
      #     'Table, café',
      #     '1,001 Arabian Nights',
      #     "foo\n\nbar"
      #   ]
      #   expected = [
      #     'oświęcim (poland)',
      #     'oswiecim, poland',
      #     'iași, romania',
      #     'iasi, romania',
      #     'table, café',
      #     '1,001 arabian nights',
      #     "foo\n\nbar"
      #   ]
      #   results = input.map{ |str| util.call(str) }
      #   expect(results).to eq(expected)
      # @example to_ascii, nonword
      #   util = Kiba::Extend::Utils::StringNormalizer.new(
      #     xforms: [:to_ascii, :nonword]
      #   )
      #   input = [
      #     'Oświęcim (Poland)',
      #     'Oswiecim, Poland',
      #     'Iași, Romania',
      #     'Iasi, Romania',
      #     'Table, café',
      #     '1,001 Arabian Nights',
      #     "foo\n\nbar"
      #   ]
      #   expected = [
      #    'OswiecimPoland',
      #    'OswiecimPoland',
      #    'IaiRomania',
      #    'IasiRomania',
      #    'Tablecafe',
      #    '1001ArabianNights',
      #    'foobar'
      #   ]
      #   results = input.map{ |str| util.call(str) }
      #   expect(results).to eq(expected)
      # @example :cspaceid mode
      #   util = Kiba::Extend::Utils::StringNormalizer.new(mode: :cspaceid)
      #   input = [
      #     'Oświęcim (Poland)',
      #     'Oswiecim, Poland',
      #     'Iași, Romania',
      #     'Iasi, Romania'
      #   ]
      #   expected = [
      #    'oswiecimpoland',
      #    'oswiecimpoland',
      #    'iasiromania',
      #    'iasiromania'
      #   ]
      #   results = input.map{ |str| util.call(str) }
      #   expect(results).to eq(expected)
      # @example Punctuation, custom proc
      #   util = Kiba::Extend::Utils::StringNormalizer.new(
      #     xforms: [:punct, ->(val) { val.upcase }]
      #   )
      #   input = ["Release the bats!!"]
      #   expected = ["RELEASE THE BATS"]
      #   results = input.map{ |str| util.call(str) }
      #   expect(results).to eq(expected)
      #
      # @since 3.3.0
      class StringNormalizer
        class << self
          # (see #initialize)
          # @param str [String] to normalize
          def call(str:, mode: nil, replacements: {}, xforms: [])
            new(
              mode: mode,
              replacements: replacements,
              xforms: xforms
            ).call(str)
          end
        end

        # ## Defined xforms
        #
        # - :nfkc - ON BY DEFAULT: Applies Unicode compatibility decomposition,
        #   followed by canonical composition; See
        #   https://unicode.org/reports/tr15/ for more details than you want.
        # - :replace - ON BY DEFAULT: performs find-and-replace operations
        #   specified in `replacements` parameter
        # - :blank - deletes all spaces and tabs, using Ruby /\p{Blank}/ regexp
        # - :lower - downcase the string
        # - :nonword - removes ALL characters that are not letters, numbers, or
        #   underscores
        # - :punct - removes all characters matching Ruby /\p{Punct}/ regexp
        # - :to_ascii - replaces non-ASCII characters with an ASCII
        #   approximation, or if none exists, a replacement character which
        #   defaults to "?".
        #
        # ## Defined modes
        #
        # - :cspaceid - replaces weird characters that don't convert to
        #   ASCII properly, :to_ascii, :nonword, :lower
        # @param mode [:cspaceid] Use an established set of xforms and
        #   replacement settings
        # @param replacements [Hash{Regexp => String}] simple `gsub`
        #   find/replaces to be applied, in order, to the string being
        #   normalized; key is the find/match value; value is the replacement
        #   string
        # @param xforms [Array<Symbol, Proc>] Symbol must match one of the
        #   defined transforms; A Proc that takes one String arg and returns
        #   a String may also be passed to apply uncommon normalization logic
        def initialize(mode: nil, replacements: {}, xforms: [])
          @mode = mode
          @replacements = replacements
          @xforms = %i[nfkc replace] + xforms
          apply_mode_settings
        end

        def call(val)
          return val if val.blank?

          xforms.inject(val) { |res, nv| do_xform(res, nv) }
        end

        private

        attr_reader :mode, :replacements, :downcased, :xforms

        def apply_mode_settings
          case mode
          when :cspaceid
            @replacements = Cspace.shady_characters
              .merge(replacements)
            xforms << :to_ascii
            xforms << :nonword
            xforms << :lower
          else
            replacements.freeze
          end
        end

        def do_xform(val, xform)
          return xform.call(val) if xform.respond_to?(:call)

          send(xform).call(val)
        end

        def blank = ->(val) { val.gsub(/\p{Blank}/, "") }

        def lower = ->(val) { val.downcase }

        def nfkc
          ->(val) do
            return val if val.unicode_normalized?(:nfkc)

            val.unicode_normalize(:nfkc)
          end
        end

        def nonword = ->(val) { val.gsub(/\W/, "") }

        def punct = ->(val) { val.gsub(/\p{Punct}/, "") }

        def replace
          ->(val) do
            replacements.inject(val) { |res, nv| res.gsub(nv[0], nv[1]) }
          end
        end

        def to_ascii
          ->(val) { ActiveSupport::Inflector.transliterate(val) }
        end
      end
    end
  end
end
