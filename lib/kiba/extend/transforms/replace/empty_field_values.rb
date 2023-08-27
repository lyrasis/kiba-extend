# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Replace
        # @since 2.9.0
        #
        # Replace empty field values the given value
        #
        # rubocop:todo Layout/LineLength
        # Works on single or multivalue fields. Can be given a `treat_as_null` value to count as empty.
        # rubocop:enable Layout/LineLength
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
        # rubocop:todo Layout/LineLength
        # transform Replace::EmptyFieldValues, fields: %i[name sex], value: '%NULLVALUE%'
        # rubocop:enable Layout/LineLength
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
        # rubocop:todo Layout/LineLength
        # transform Replace::EmptyFieldValues, fields: %i[name sex], value: '%NULLVALUE%',
        # rubocop:enable Layout/LineLength
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
        # rubocop:todo Layout/LineLength
        # transform Replace::EmptyFieldValues, fields: %i[name sex], delim: '|', value: '%NULLVALUE%'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        #   {species: 'guineafowl', name: '%NULL%', sex: '%NULL%'},
        # rubocop:todo Layout/LineLength
        #   {species: 'guineafowl', name: 'Weddy|%NULLVALUE%|Grimace|%NULLVALUE%', sex: '%NULLVALUE%'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {species: 'guineafowl', name: '%NULLVALUE%|Weddy|Grimace|%NULLVALUE%', sex: '%NULL%|m|m|%NULLVALUE%'}
        # rubocop:enable Layout/LineLength
        # ]
        # ```
        #
        # ### Multivalued (given a `delim` value) with `treat_as_null`
        #
        # Using same source data as above, and transform set up as:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Replace::EmptyFieldValues, fields: %i[name sex], delim: '|', value: '%NULLVALUE%',
        # rubocop:enable Layout/LineLength
        #   treat_as_null: '%NULL%'
        # ```
        #
        # Results in:
        #
        # ```
        # [
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%' },
        #   {species: 'guineafowl', name: '%NULLVALUE%', sex: '%NULLVALUE%'},
        # rubocop:todo Layout/LineLength
        #   {species: 'guineafowl', name: 'Weddy|%NULLVALUE%|Grimace|%NULLVALUE%', sex: '%NULLVALUE%'},
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   {species: 'guineafowl', name: '%NULLVALUE%|Weddy|Grimace|%NULLVALUE%', sex: '%NULLVALUE%|m|m|%NULLVALUE%'}
        # rubocop:enable Layout/LineLength
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
        # rubocop:todo Layout/LineLength
        # transform Replace::EmptyFieldValues, fields: %i[name sex], value: '%NULLVALUE%',
        # rubocop:enable Layout/LineLength
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
          # rubocop:todo Layout/LineLength
          # @param fields [Array(Symbol), Symbol] in which to perform replacements
          # rubocop:enable Layout/LineLength
          # @param value [String] replaces the empty value(s)
          # rubocop:todo Layout/LineLength
          # @param delim [String, nil] if provided, replacement of individual empty values in a multivalue
          # rubocop:enable Layout/LineLength
          #   field will be performed after splitting on this string
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [String, Array(String)] string(s) to treat as empty values
          # rubocop:enable Layout/LineLength
          def initialize(fields:, value:, delim: nil, treat_as_null: "")
            @fields = [fields].flatten
            @value = value
            @delim = delim
            @treat_as_null = treat_as_null
            @initial_getter = Helpers::FieldValueGetter.new(fields: fields,
              discard: [])
            @replacement_getter = Helpers::FieldValueGetter.new(fields: fields,
              delim: delim)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            replace_fully_empty_fields(row)
            replace_multival_empty(row) if delim
            row
          end

          private

          attr_reader :fields, :value, :delim, :treat_as_null, :initial_getter,
            :replacement_getter

          def is_empty?(val)
            [nil, "", treat_as_null].flatten.any?(val)
          end

          def replace_fully_empty_fields(row)
            initial_getter.call(row)
              .select { |field, value| is_empty?(value) }
              .keys
              .each { |field| row[field] = value }
          end

          def replace_empty_multivals(row, field, vals)
            row[field] = vals.map do |val|
              is_empty?(val) ? value : val
            end.join(delim)
          end

          def replace_multival_empty(row)
            replacement_getter.call(row)
              .select { |field, val| val[delim] }
              .transform_values { |val| val.split(delim, -1) }
              .select { |field, vals| vals.any? { |mval| is_empty?(mval) } }
              .each { |field, vals| replace_empty_multivals(row, field, vals) }
          end
        end
      end
    end
  end
end
