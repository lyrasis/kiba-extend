# frozen_string_literal: true

module Kiba
  module Extend
    module Data
      class ConvertibleFraction
        include Comparable
        attr_reader :whole, :fraction, :position
        
        # @param whole [Integer] whole number preceding a fraction
        # @param fraction [String]
        # @param position [Range] indicates position of fractional data within original string
        def initialize(whole: 0, fraction:, position:)
          fail(TypeError, '`whole` must be an Integer') unless whole.is_a?(Integer)
          fail(TypeError, '`position` must be a Range') unless position.is_a?(Range)
          @whole = whole.freeze
          @fraction = fraction.freeze
          @position = position.freeze
        end

        def replace_in(val:, places: 4)
          return val unless convertible?

          [prefix ? val[prefix] : '', to_s(places), val[suffix]].compact.join
        end
        
        def to_f
          return nil unless convertible?

          ( Rational(fraction) + whole ).to_f
        end

        # @param places [Integer]
        def to_s(places = 4)
          return nil unless convertible?

          ( Rational(fraction) + whole ).round(+places).to_f.to_s
        end

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

