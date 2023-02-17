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
      # ```
      #   # first initialize an instance of the class as an instance variable in
      #   #   your context
      #   @normalizer = StringNormalizer.new(downcased: false)
      #
      #   # for the repetitive part:
      #   vals.each{ |val| @normalizer.call(val) }
      # ```
      #
      # For one-off usage, or where the normalization settings vary per
      #   normalized value, you can do:
      #
      # ```
      # StringNormalizer.call(downcased: false, str: 'Table, café')
      #   => 'Tablecafe'
      # ```
      #
      # The second way is much less performant, as it initializes a new instance
      #   of the class every time it is called.
      #
      # @example Default settings
      #   util = Kiba::Extend::Utils::StringNormalizer.new
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
      #    'oswiecimpoland',
      #    'oswiecimpoland',
      #    'iairomania',
      #    'iasiromania',
      #    'tablecafe',
      #    '1001arabiannights',
      #    'foobar'
      #   ]
      #   results = input.map{ |str| util.call(str) }
      #   expect(results).to eq(expected)
      # @example downcased = false
      #   util = Kiba::Extend::Utils::StringNormalizer.new(downcased: false)
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
      #
      # @since 3.3.0
      class StringNormalizer
        class << self
          # @param mode [:plain, :cspaceid] :plain does no find/replace before
          #   transliterating. :cspaceid does, due to characters it is known to
          #   handle weirdly internally
          # @param downcased [Boolean] whether to downcase result
          # @param str [String] to normalize
          def call(mode: :plain, downcased: true, str:)
            self.new(mode: mode, downcased: downcased).call(str)
          end
        end

        # @param mode [:plain, :cspaceid] :plain does no find/replace before
        #   transliterating. :cspaceid does, due to characters it is known to
        #   handle weirdly internally
        # @param downcased [Boolean] whether to downcase result
        def initialize(mode: :plain, downcased: true)
          @mode = mode
          @downcased = downcased
          @subs = set_subs
        end

        def call(val)
          unless val.unicode_normalized?(:nfkc)
            val = val.unicode_normalize(:nfkc)
          end
          subs.each { |old, new| val = val.gsub(old, new) }

          val = ActiveSupport::Inflector.transliterate(val).gsub(/\W/, '')

          downcased ? val.downcase : val
        end

        private

        attr_reader :mode, :downcased, :subs

        def set_subs
          case mode
          when :cspaceid
            Cspace.shady_characters
          else
            {}.freeze
          end
        end
      end
    end
  end
end
