# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Clean
        # Removes all leading/trailing spaces from values in the specified
        #   fields.
        #
        # @example Basic match(default)
        #   # Used in pipeline as:
        #   # transform Clean::StripFields,
        #   #   fields: :val
        #   xform = Clean::StripFields.new(
        #     fields: :val
        #   )
        #   input = [
        #     {val: '  foo  '},
        #     {val: ' foo | bar '},
        #     {val: ''},
        #     {val: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'foo'},
        #     {val: 'foo | bar'},
        #     {val: ''},
        #     {val: nil}
        #   ]
        #   expect(result).to eq(expected)
        # @example Multivalue mode (i.e. with delim)
        #   # Used in pipeline as:
        #   # transform Clean::StripFields,
        #   #   fields: :val,
        #   #   delim: '|'
        #   xform = Clean::StripFields.new(
        #     fields: :val,
        #     delim: '|'
        #   )
        #   input = [
        #     {val: '  foo  '},
        #     {val: ' foo | bar '},
        #     {val: ''},
        #     {val: nil}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {val: 'foo'},
        #     {val: 'foo|bar'},
        #     {val: ''},
        #     {val: nil}
        #   ]
        #   expect(result).to eq(expected)
        class StripFields
          include Allable

          # @param fields [Array<Symbol>,Symbol,:all, nil] in which to
          #   strip values
          # @param delim [nil,String] if given, switches to multivalue mode, in
          #   which each value in a multivalued string is stripped
          def initialize(fields:, delim: nil)
            @fields = [fields].flatten
            @delim = delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row)
            fields.each{ |field| strip_field(field, row) }

            row
          end

          private

          attr_reader :fields, :delim

          def strip_field(field, row)
            val = row[field]
            return if val.blank?

            row[field] = stripped(val)
          end

          def stripped(val)
            if delim && val[delim]
              val.split(delim)
                .map{ |value| value.strip }
                .join(delim)
            else
              val.strip
            end
          end
        end
      end
    end
  end
end
