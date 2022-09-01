# frozen_string_literal: true

require 'measured'

module Kiba
  module Extend
    module Transforms
      module Fraction
        class ToDecimal
          # @param fields [Symbol, Array(Symbol)] Source data fields. If no targets given, converted values are
          #   written back into the original fields.
          # @param targets [nil, Symbol, Array(Symbol)] Target data fields, if different from source data fields.
          #   If `targets` are specified at all, a target must be specified for each value in `fields`. The target
          #   for a given field can be the same as the given field, however.
          # @param target_format [:string, :float] If fractions are being extracted from longer text strings and replaced,
          #   this should always be `:string`. Likewise if there may be more than one fraction in a given field value.
          #   This is the usual expected case. If the source data fields are known to only contain single fraction
          #   values and you need to use them in calculations in subsequent transforms within the same job, you may
          #   wish to set this as `:float` for greater accuracy.
          # @param places [Integer] Number of decimal places. Applied if `target_format` = `:string`
          # @param pre [Array(String)] List of characters/strings that precede a fraction. These are removed in the
          #   result
          # @param delete_sources [Boolean] If `targets` are given, `fields` are deleted from row. Has no effect
          #   if no `targets` are given, or if the target for a field equals the field.
          def initialize(fields:,
                         targets: nil,
                         target_format: :string,
                         places: 4,
                         pre: [' ', '-'],
                         delete_sources: false)
            @fields = [fields].flatten
            @targets = targets ? [targets].flatten : nil
            @target_format = target_format
            @places = places
            @delete_sources = delete_sources
            @extractor = Kiba::Extend::Utils::ExtractFractions.new(pre: pre)
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            fields.each{ |field| to_decimal(field, row) }
            row
          end

          private

          attr_reader :fields, :targets, :target_format, :places, :delete_sources, :extractor

          def replace_fractions(fractions, value)
            val = value.dup
            fractions.each do |fraction|
              val = fraction.replace_in(val: val, places: places)
            end
            val
          end
          
          def to_decimal(field, row)
            targetfield = target(field)
            fieldval = row[field]
            row[targetfield] = fieldval
            return if fieldval.blank?

            fractions = extractor.call(fieldval)
            return if fractions.empty?

            row[targetfield] = replace_fractions(fractions, fieldval)
          end

          def target(srcfield)
            return srcfield unless targets

            ind = fields.find_index(srcfield)
            targets[ind]
          end
        end
      end
    end
  end
end
