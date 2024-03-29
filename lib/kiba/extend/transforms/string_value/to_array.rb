# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module StringValue
        # @since 3.3.0
        #
        # Splits given field value into an array on given delimiter.
        # Wraps field value in an array if `delim` is explicitly set to `nil`.
        #
        # @example Delimiter is provided
        #   # Used in pipeline as:
        #   # transform StringValue::ToArray, fields: :r1, delim: ';'
        #   xform = StringValue::ToArray.new(fields: :r1, delim: ';')
        #   input = [
        #     {r1: 'a;b', r2: 'foo;bar'}
        #   ]
        #   result = input.map{|row| xform.process(row)}
        #   expected = [
        #     {r1: ['a','b'], r2: 'foo;bar'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Delimiter is not provided
        #   # Used in pipeline as:
        #   # transform StringValue::ToArray, fields: :r1
        #   xform = StringValue::ToArray.new(fields: :r1)
        #   input = [
        #     {r1: 'a|b', r2: 'foo|bar'}
        #   ]
        #   result = input.map{|row| xform.process(row)}
        #   expected = [
        #     {r1: ['a','b'], r2: 'foo|bar'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Delimiter is nil
        #   # Used in pipeline as:
        #   # transform StringValue::ToArray, fields: :r1, delim: nil
        #   xform = StringValue::ToArray.new(fields: :r1, delim: nil)
        #   input = [
        #     {r1: 'a;b', r2: 'foo;bar'}
        #   ]
        #   result = input.map{|row| xform.process(row)}
        #   expected = [
        #     {r1: ['a;b'], r2: 'foo;bar'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Mulitple fields using default delimiter
        #   # Used in pipeline as:
        #   # transform StringValue::ToArray, fields: %i[r1 r2]
        #   xform = StringValue::ToArray.new(fields: [:r1,:r2])
        #   input = [
        #     {r1: 'a|b', r2: 'foo|bar'}
        #   ]
        #   result = input.map{|row| xform.process(row)}
        #   expected = [
        #     {r1: ['a','b'], r2: ['foo','bar']}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Empty array when fieldval is nil and delim is nil
        #   # Used in pipeline as:
        #   # transform StringValue::ToArray, fields: :r1, delim: nil
        #   xform = StringValue::ToArray.new(fields: :r1, delim: nil)
        #   input = [
        #     {r1: nil, r2: 'foo;bar'}
        #   ]
        #   result = input.map{|row| xform.process(row)}
        #   expected = [
        #     {r1: [], r2: 'foo;bar'}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Empty array when fieldval is nil
        #   # Used in pipeline as:
        #   # transform StringValue::ToArray, fields: :r1
        #   xform = StringValue::ToArray.new(fields: :r1)
        #   input = [
        #     {r1: nil, r2: 'foo;bar'}
        #   ]
        #   result = input.map{|row| xform.process(row)}
        #   expected = [
        #     {r1: [], r2: 'foo;bar'}
        #   ]
        #   expect(result).to eq(expected)
        class ToArray
          # @param fields [Symbol, Array(Symbol)] Source data fields.
          # @param delim [String, nil] The delimiting character. If no delim is
          #   given, the default delim is `Kiba::Extend.delim`. If `nil` is
          #   provided (do not delimit string value), the string value will
          #   instead be wrapped in an array without attempting to split the
          #   string value. If `nil` is provided for delim and a field's value
          #   is nil, this will create an empty array.
          def initialize(fields:, delim: Kiba::Extend.delim)
            @fields = [fields].flatten
            @delim = delim
          end

          def process(row)
            fields.each do |field|
              fieldval = row[field]
              row[field] = if delim.nil?
                fieldval.nil? ? [] : [fieldval]
              else
                fieldval.nil? ? [] : fieldval.split(delim)
              end
            end

            row
          end

          attr_reader :fields, :delim
        end
      end
    end
  end
end
