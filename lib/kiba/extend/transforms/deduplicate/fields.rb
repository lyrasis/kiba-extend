# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Removes the value(s) of `source` from `targets`
        #
        # Input table:
        #
        # ```
        # | x   | y   | z   |
        # |-----+-----+-----|
        # | a   | a   | b   |
        # | a   | a   | a   |
        # | a   | b;a | a;c |
        # | a;b | b;a | a;c |
        # | a   | aa  | bat |
        # | nil | a   | nil |
        # |     | ;a  | b;  |
        # | a   | nil | nil |
        # | a   | A   | a   |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::Fields, source: :x, targets: %i[y z], multival: true, sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | x   | y   | z   |
        # |-----+-----+-----|
        # | a   | nil | b   |
        # | a   | nil | nil |
        # | a   | b   | c   |
        # | a;b | nil | c   |
        # | a   | aa  | bat |
        # | nil | a   | nil |
        # |     | a   | b   |
        # | a   | nil | nil |
        # | a   | A   | nil |
        # ```
        #
        # Input table:
        #
        # ```
        # | x | y | z |
        # |---+---+---|
        # | a | A | a |
        # | a | a | B |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::Fields,
        #    source: :x,
        #    targets: %i[y z],
        #    multival: true,
        #    sep: ';',
        #    casesensitive: false
        # ```
        #
        # Results in:
        #
        # ```
        # | x | y   | z   |
        # |---+-----+-----|
        # | a | nil | nil |
        # | a | nil | B   |
        # ```
        #
        class Fields
          # @param source [Symbol] name of field containing value to remove from target fields
          # @param targets [Array<Symbol>] names of fields to remove source value(s) from
          # @param casesensitive [Boolean] whether matching should be case sensitive
          # @param multival [Boolean] whether to treat as multi-valued
          # @param sep [String] used to split/join multi-val field values
          def initialize(source:, targets:, casesensitive: true,
            multival: false, sep: Kiba::Extend.delim)
            @source = source
            @targets = targets
            @casesensitive = casesensitive
            @multival = multival
            @sep = sep
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            sourceval = row.fetch(@source, nil)
            return row if sourceval.nil?

            targetvals = @targets.map { |target| row.fetch(target, nil) }
            return row if targetvals.compact.empty?

            sourceval = @multival ? sourceval.split(@sep,
              -1).map(&:strip) : [sourceval.strip]
            targetvals = if @multival
              targetvals.map { |val|
                val.split(@sep, -1).map(&:strip)
              }
            else
              targetvals.map { |val| [val.strip] }
            end

            if sourceval.blank?
              targetvals = targetvals.map { |vals| vals.reject(&:blank?) }
            elsif @casesensitive
              targetvals = targetvals.map { |vals| vals - sourceval }
            else
              sourceval = sourceval.map(&:downcase)
              targetvals = targetvals.map { |vals|
                vals.reject { |val|
                  sourceval.include?(val.downcase)
                }
              }
            end

            targetvals = if @multival
              targetvals.map { |vals| vals&.join(@sep) }
            else
              targetvals.map(&:first)
            end
            targetvals = targetvals.map { |val| val.blank? ? nil : val }

            targetvals.each_with_index { |val, i| row[@targets[i]] = val }

            row
          end
        end
      end
    end
  end
end
