# frozen_string_literal: true

require "strscan"

module Kiba
  module Extend
    module Utils
      # Extracts {Data::ConvertibleFraction}(s) from given String and returns
      #   only fractions that can be converted to decimal, in the order they
      #   will need to be replaced in the string
      class ExtractFractions
        # @param whole_fraction_sep [Array(String)] List of characters that
        #   precede a fraction after a whole number, indicating that the whole
        #   number and fraction should be extracted together. If this is
        #   set to `[' ', '-']` (the default), then both `1 1/2` and `1-1/2`
        #   will be extracted with `1` as the whole number and `1/2` as the
        #   fraction, and converted to `1.5`. If this is set to `[' ']`, then
        #   `1 1/2` will be extracted as described preveiously. For `1-1/2`, no
        #   whole number value will be extracted. `1/2` will be extracted as the
        #   fraction, and it will be converted to '0.5'.
        def initialize(whole_fraction_sep: [" ", "-"])
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
            unless fraction.convertible?
              warn("#{self.class.name}: Unconvertible fraction: #{value[fraction.position]}")
            end
          end
          result.sort.reverse
        end

        private

        attr_reader :fpattern, :whole_fraction_sep, :fraction

        def extract_fraction(scanner, result)
          startpos = scanner.pos
          scanner.scan(fpattern)
          result << fraction.new(fraction: scanner.captures[0],
            position: startpos..scanner.pos - 1)
        end

        def try_whole_fraction_extract(scanner, result)
          startpos = scanner.pos
          whole_num = scanner.scan(/\d+/).to_i
          sep = scanner.scan(/./)
          fmatch = scanner.match?(fpattern)
          if whole_fraction_sep.any?(sep) && fmatch
            result << fraction.new(whole: whole_num,
              fraction: scanner.scan(fpattern), position: startpos..scanner.pos - 1)
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
