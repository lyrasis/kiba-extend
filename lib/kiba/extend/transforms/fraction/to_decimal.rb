# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Fraction
        # Converts fractions expressed like "1 1/4" to decimals like "1.25"
        #
        # @example Defaults and general behavior/value handling
        #   # Used in pipeline as:
        #   # transform Fraction::ToDecimal, fields: :dim
        #   xform = Fraction::ToDecimal.new(fields: :dim)
        #   input = [
        #     {dim: nil},
        #     {dim: ''},
        #     {dim: 'foo'},
        #     {dim: '1/2'},
        #     {dim: '6-1/4 x 9-1/4'},
        #     {dim: '10 5/8x13'},
        #     {dim: '1 2/3 x 5 1/2'},
        #     {dim: 'approximately 2/3 by 1/2in (height unknown)'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {dim: nil},
        #     {dim: ''},
        #     {dim: 'foo'},
        #     {dim: '0.5'},
        #     {dim: '6.25 x 9.25'},
        #     {dim: '10.625x13'},
        #     {dim: '1.6667 x 5.5'},
        #     {dim: 'approximately 0.6667 by 0.5in (height unknown)'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Multiple fields and targets
        #   # Used in pipeline as:
        #   # transform Fraction::ToDecimal, fields: %i[w h], targets: %i[width height]
        #   xform = Fraction::ToDecimal.new(fields: %i[w h], targets: %i[width height])
        #   input = [{w: '8 1/2', h: '11'}]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [{w: '8 1/2', h: '11', width: '8.5', height: '11'}]
        #   expect(result).to eq(expected)
        #
        # @example Multiple fields and targets, and `delete_sources` = true
        #   # Used in pipeline as:
        #   # transform Fraction::ToDecimal, fields: %i[w h], targets: %i[w height], delete_sources: true
        #   xform = Fraction::ToDecimal.new(fields: %i[w h], targets: %i[w height], delete_sources: true)
        #   input = [{w: '8 1/2', h: '11'}]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [{w: '8.5', height: '11'}]
        #   expect(result).to eq(expected)
        #
        # @example `target_format: :float` and `places: 2`
        #   # Used in pipeline as:
        #   # transform Fraction::ToDecimal, fields: :w, target_format: :float, places: 2
        #   xform = Fraction::ToDecimal.new(fields: :w, target_format: :float, places: 2)
        #   input = [
        #     {w: '8-2/3'},
        #     {w: '2/3 in'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {w: 8.67},
        #     {w: '0.67 in'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example `target_format: :float, places: 2, whole_fraction_sep: [' ']`
        #   # Used in pipeline as:
        #   # transform Fraction::ToDecimal,
        #   #   fields: :w,
        #   #   target_format: :float,
        #   #   places: 2,
        #   #   whole_fraction_sep: [' ']
        #   xform = Fraction::ToDecimal.new(
        #     fields: :w, target_format: :float, places: 2, whole_fraction_sep: [' ']
        #   )
        #   input = [
        #     {w: '8-2/3'},
        #     {w: '2/3 in'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {w: '8-0.67'},
        #     {w: '0.67 in'}
        #   ]
        #   expect(result).to eq(expected)
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
          # @param whole_fraction_sep [Array(String)] List of characters that precede a fraction after a whole
          #   number, indicating that the whole number and fraction should be extracted together.
          #   See {Utils::ExtractFractions} for further explanation.
          # @param delete_sources [Boolean] If `targets` are given, `fields` are deleted from row. Has no effect
          #   if no `targets` are given, or if the target for a field equals the field.
          def initialize(fields:,
                         targets: nil,
                         target_format: :string,
                         places: 4,
                         whole_fraction_sep: [' ', '-'],
                         delete_sources: false)
            @fields = [fields].flatten
            @targets = targets ? [targets].flatten : nil
            @target_format = target_format
            @places = places
            @delete_sources = delete_sources
            @extractor = Kiba::Extend::Utils::ExtractFractions.new(whole_fraction_sep: whole_fraction_sep)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            fields.each{ |field| to_decimal(field, row) }
            delete_source_fields(row)
            row
          end

          private

          attr_reader :fields, :targets, :target_format, :places, :delete_sources, :extractor

          def delete_source_fields(row)
            return unless delete_sources && targets

            fields.each_with_index do |field, ind|
              row.delete(field) unless targets[ind] == field
            end
          end

          def floatable?(value)
            true unless value.match?(/[^0-9.]/)
          end

          def format_field_value(value)
            return value unless target_format == :float && floatable?(value)

            value.to_f
          end

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

            replaced = replace_fractions(fractions, fieldval)
            formatted = format_field_value(replaced)

            row[targetfield] = formatted
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
