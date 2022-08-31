# frozen_string_literal: true

require 'strscan'

module Kiba
  module Extend
    module Utils
      class ExtractFractions
        # @param pre [Array(String)] List of characters/strings that precede a fraction. These are removed in the
        #   result
        def initialize(pre: [' ', '-'])
          @pre = pre
          @pattern = /(\d+)(?:#{pre.join('|')})(\d+\/\d+|\d+\/\d+)/
          @fpattern = /(\d+\/\d+)/
          @wfpattern = /(\d+)(?:#{pre.join('|')})(\d+\/\d+)/
          @fklass = Kiba::Extend::Data::ConvertibleFraction
        end

        # @param value [String]
        def call(value)
          result = []
          scanner = StringScanner.new(value)
          scan(scanner, result)
          result.sort.reverse
        end
        
        private

        attr_reader :pattern, :fpattern, :wfpattern, :fklass

        def extract_fraction(scanner, result)
          startpos = scanner.pos
          chk = scanner.scan(fpattern)
          return unless chk

          result << fklass.new(**{fraction: scanner.captures[0], position: startpos..scanner.pos - 1 })
        end

        def extract_whole_fraction(scanner, result)
          startpos = scanner.pos
          chk = scanner.scan(wfpattern)
          return unless chk

          result << fklass.new(**{whole: scanner.captures[0].to_i, fraction: scanner.captures[1], position: startpos..scanner.pos - 1 })
        end
        
        def scan(scanner, result)
          return if scanner.eos?
          return if scanner.rest_size < 3
          return unless scanner.exist?(fpattern) || scanner.exist?(wfpattern)

          scan_next(scanner, result)
        end

        def scan_next(scanner, result)
          scanner.skip(/\D+/)
          if scanner.match?(fpattern)
            extract_fraction(scanner, result)
          elsif scanner.match?(wfpattern)
            extract_whole_fraction(scanner, result)
          else
            scanner.skip(/./)
          end
          scan(scanner, result)
        end
      end
    end
  end
end
