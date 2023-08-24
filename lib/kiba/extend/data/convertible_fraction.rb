# frozen_string_literal: true

module Kiba
  module Extend
    module Data
      # Value object encoding an extracted string fraction (e.g. '1 1/2') so it can be converted.
      #
      # Can represent invalid/non-convertible "fractions"
      class ConvertibleFraction
        include Comparable

        attr_reader :whole, :fraction, :position

        # @param whole [Integer] whole number preceding a fraction
        # @param fraction [String]
        # @param position [Range] indicates position of fractional data within original string
        def initialize(fraction:, position:, whole: 0)
          unless whole.is_a?(Integer)
            fail(TypeError,
              "`whole` must be an Integer")
          end
          unless position.is_a?(Range)
            fail(TypeError,
              "`position` must be a Range")
          end
          @whole = whole.freeze
          @fraction = fraction.freeze
          @position = position.freeze
        end

        # @param val [String] the value in which textual fraction will be replaced with a decimal
        # @param places [Integer] maximum number of decimal places to keep in the resulting decimal value
        # @return [String]
        def replace_in(val:, places: 4)
          return val unless convertible?

          [prefix ? val[prefix] : "", to_s(places), val[suffix]].compact.join
        end

        # @return [Float]
        def to_f
          return nil unless convertible?

          (Rational(fraction) + whole).to_f
        end

        # @param places [Integer]
        # @return [String]
        def to_s(places = 4)
          return nil unless convertible?

          (Rational(fraction) + whole).round(+places).to_f.to_s
        end

        # @return [Boolean] whether the fraction is indeed convertible
        def convertible?
          Rational(fraction)
        rescue ZeroDivisionError
          false
        else
          true
        end

        def ==(other)
          whole == other.whole && fraction == other.fraction && position == other.position
        end
        alias_method :eql?, :==

        def <=>(other)
          position.first <=> other.position.first
        end

        def hash
          [self.class, whole, fraction, position].hash
        end

        def to_h
          {whole: whole, fraction: fraction, position: position}
        end

        private

        def prefix
          return nil if position.min == 0

          0..position.min - 1
        end

        def suffix
          position.max + 1..-1
        end
      end
    end
  end
end
