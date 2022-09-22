# frozen_string_literal: true

require 'strscan'

module Kiba
  module Extend
    module Utils
      # Extracts {Data::ConvertibleFractions} from given String and returns only fractions that can be
      #   converted to decimal, in the order they will need to be replaced in the string
      class ExtractFractions
        # @param whole_fraction_sep [Array(String)] List of characters that precede a fraction after a whole number,
        #   indicating that the whole number and fraction should be extracted together.
        def initialize(whole_fraction_sep: [' ', '-'])
          @whole_fraction_sep = whole_fraction_sep
          @fpattern = /(\d+\/\d+)/
          @fraction = Kiba::Extend::Data::ConvertibleFraction
        end

        # @param value [String]
        def call(value)
          return [] unless value.match?(fpattern)
          
          result = []
          scanner = StringScanner.new(value)
          scan(scanner, result)
          result.each do |fraction|
            warn("#{self.class.name}: Unconvertible fraction: #{value[fraction.position]}") unless fraction.convertible?
          end
          result.sort.reverse
        end
        
        private

        attr_reader :fpattern, :whole_fraction_sep, :fraction

        def extract_fraction(scanner, result)
          startpos = scanner.pos
          scanner.scan(fpattern)
          result << fraction.new(**{fraction: scanner.captures[0], position: startpos..scanner.pos - 1 })
        end

        def try_whole_fraction_extract(scanner, result)
          startpos = scanner.pos
          whole_num = scanner.scan(/\d+/).to_i
          sep = scanner.scan(/./)
          fmatch = scanner.match?(fpattern)
          if whole_fraction_sep.any?(sep) && fmatch
            result << fraction.new(**{whole: whole_num, fraction: scanner.scan(fpattern), position: startpos..scanner.pos - 1 })
          end
        end

        def scan(scanner, result)
          return if scanner.eos?
          return if scanner.rest_size < 3
          return unless scanner.exist?(fpattern)

          scan_next(scanner, result)
        end

        def scan_next(scanner, result)
          scanner.skip(/\D+/)
          if scanner.match?(fpattern)
            extract_fraction(scanner, result)
          else
            try_whole_fraction_extract(scanner, result)
          end
          scan(scanner, result)
        end
      end
    end
  end
end
