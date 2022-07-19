# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # Replace empty field values the given value
        #
        # Works on single or multivalue fields. Can be given a `treat_as_null` value to count as empty.
        #
        # ## Examples
        #
        # ### Defaults (single value, replaces truly nil or empty values)
        #
        # Source data:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: nil, sex: ''},
        #   {species: 'guineafowl', name: '%NULL%', sex: '%NULL%'},
        #   {species: 'guineafowl', name: 'Weddy||Grimace|', sex: ''},
        #   {species: 'guineafowl', name: '|Weddy|Grimace|', sex: '%NULL%|m|m|'}
        # ]
        # ```
        #
        # Used as:
        #
        # ```
        # transform Replace::EmptyFieldValues, fields: %i[name sex], value: '%NULLVALUE%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        #   {species: 'guineafowl', name: '%NULL%', sex: '%NULL%'},
        #   {species: 'guineafowl', name: 'Weddy||Grimace|', sex: '%NULLVALUE%'}
        #   {species: 'guineafowl', name: '|Weddy|Grimace|', sex: '%NULL%|m|m|'}
        # ]
        # ```
        #
        # ### Null placeholder (single value)
        #
        # Using same source data as above, and transform set up as: 
        #
        # ```
        # transform Replace::EmptyFieldValues, fields: %i[name sex], value: '%NULLVALUE%',
        #   treat_as_null: '%NULL%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%'},
        #   {species: 'guineafowl', name: 'Weddy||Grimace|', sex: '%NULLVALUE%'}
        #   {species: 'guineafowl', name: '|Weddy|Grimace|', sex: '%NULL%|m|m|'}
        # ]
        # ```
        #
        # ### Multivalued (given a `delim` value)
        #
        # Using same source data as above, and transform set up as: 
        #
        # ```
        # transform Replace::EmptyFieldValues, fields: %i[name sex], delim: '|', value: '%NULLVALUE%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        #   {species: 'guineafowl', name: '%NULL%', sex: '%NULL%'},
        #   {species: 'guineafowl', name: 'Weddy|%NULLVALUE%|Grimace|%NULLVALUE%', sex: '%NULLVALUE%'},
        #   {species: 'guineafowl', name: '%NULLVALUE%|Weddy|Grimace|%NULLVALUE%', sex: '%NULL%|m|m|%NULLVALUE%'}
        # ]
        # ```
        #
        # ### Multivalued (given a `delim` value) with `treat_as_null`
        #
        # Using same source data as above, and transform set up as: 
        #
        # ```
        # transform Replace::EmptyFieldValues, fields: %i[name sex], delim: '|', value: '%NULLVALUE%',
        #   treat_as_null: '%NULL%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%'},
        #   {species: 'guineafowl', name: 'Weddy|%NULLVALUE%|Grimace|%NULLVALUE%', sex: '%NULLVALUE%'},
        #   {species: 'guineafowl', name: '%NULLVALUE%|Weddy|Grimace|%NULLVALUE%', sex: '%NULLVALUE%|m|m|%NULLVALUE%'}
        # ]
        # ```
        #
        # ### Multiple `treat_as_null` values
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULL%', sex: '%NADA%' }
        # ]
        #
        # ```
        # transform Replace::EmptyFieldValues, fields: %i[name sex], value: '%NULLVALUE%',
        #   treat_as_null: ['%NULL%', '%NADA%']
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        # ]
        # ```
        class EmptyFieldValues
          # @param fields [Array(Symbol), Symbol] in which to perform replacements
          # @param value [String] replaces the empty value(s)
          # @param delim [String, nil] if provided, replacement of individual empty values in a multivalue
          #   field will be performed after splitting on this string
          # @param treat_as_null [String, Array(String)] string(s) to treat as empty values
          def initialize(fields:, value:, delim: nil, treat_as_null: '')
            @fields = [fields].flatten
            @value = value
            @delim = delim
            @treat_as_null = treat_as_null
            @initial_getter = Helpers::FieldValueGetter.new(fields: fields, discard: [])
            @replacement_getter = Helpers::FieldValueGetter.new(fields: fields, delim: delim)
          end

          # @private
          def process(row)
            replace_fully_empty_fields(row)
            replace_multival_empty(row) if delim
            row
          end

          private

          attr_reader :fields, :value, :delim, :treat_as_null, :initial_getter, :replacement_getter

          def is_empty?(val)
            [nil, '', treat_as_null].flatten.any?(val)
          end
          
          def replace_fully_empty_fields(row)
            initial_getter.call(row)
              .select{ |field, value| is_empty?(value) }
              .keys
              .each{ |field| row[field] = value }
          end

          def replace_empty_multivals(row, field, vals)
            row[field] = vals.map{ |val| is_empty?(val) ? value : val }.join(delim)
          end

          def replace_multival_empty(row)
            replacement_getter.call(row)
              .select{ |field, val| val[delim] }
              .transform_values{ |val| val.split(delim, -1) }
              .select{ |field, vals| vals.any?{ |mval| is_empty?(mval) } }
              .each{ |field, vals| replace_empty_multivals(row, field, vals) }
          end
        end
      end
    end
  end
end
