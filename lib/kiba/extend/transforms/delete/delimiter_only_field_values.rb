# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # @since 2.9.0
        #
        # rubocop:todo Layout/LineLength
        # Converts any value in given field(s) to nil if that value is `empty?`, or consists only
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   of the specified delimiter, `treat_as_null` value(s), and, optionally, spaces.
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # See also {Kiba::Extend::Transforms::Helpers::DelimOnlyChecker}, which is used by this transform.
        # rubocop:enable Layout/LineLength
        #
        # ## Examples
        #
        # ### Default
        #
        # rubocop:todo Layout/LineLength
        # Deletes delimiter-only field values from all fields. No strings except `''` (empty string) are
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   treated as null. **This assumes your project has set `Kiba::Extend.delim` to equal `|`.**
        # rubocop:enable Layout/LineLength
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a| b', bar: ' | ', baz: ''},
        #   {foo: nil, bar: '|', baz: ' |b'},
        # rubocop:todo Layout/LineLength
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%|%NULLVALUE%", baz: "%NULLVALUE%| %NULLVALUE%"},
        # rubocop:enable Layout/LineLength
        #   {foo: 'NULL', bar: "NULL |%NULLVALUE%", baz: "NULL| NULL"},
        # ]
        # ```
        #
        # Setup:
        #
        # ```
        # transform Delete::DelimiterOnlyFieldValues
        # ```
        #
        # Result:
        #
        # ```
        # [
        #   {foo: 'a| b', bar: nil, baz: nil},
        #   {foo: nil, bar: nil, baz: ' |b'},
        # rubocop:todo Layout/LineLength
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%|%NULLVALUE%", baz: "%NULLVALUE%| %NULLVALUE%"},
        # rubocop:enable Layout/LineLength
        #   {foo: 'NULL', bar: "NULL |%NULLVALUE%", baz: "NULL| NULL"},
        # ]
        # ```
        #
        # ### With non-default `delim` and `treat_as_null` parameters
        #
        # rubocop:todo Layout/LineLength
        # > **NOTE**: The replacements done to determine whether or not a value is delimiter-only are not
        # rubocop:enable Layout/LineLength
        # rubocop:todo Layout/LineLength
        #   applied to the remaining field values. Otherwise, we'd see the `%NULLVALUE%`s in the results
        # rubocop:enable Layout/LineLength
        #   transformed to `%VALUE%`.
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a; b', bar: ' ; ', baz: ''},
        #   {foo: nil, bar: ';', baz: ' ;b'},
        # rubocop:todo Layout/LineLength
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%;%NULLVALUE%", baz: "%NULLVALUE%; %NULLVALUE%"},
        # rubocop:enable Layout/LineLength
        #   {foo: 'NULL', bar: "NULL ;%NULLVALUE%", baz: "NULL; NULL"},
        # ]
        # ```
        #
        # Setup:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Delete::DelimiterOnlyFieldValues, delim: ';', treat_as_null: 'NULL'
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Result:
        #
        # ```
        # [
        #   {foo: 'a; b', bar: nil, baz: nil},
        #   {foo: nil, bar: nil, baz: ' ;b'},
        # rubocop:todo Layout/LineLength
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%;%NULLVALUE%", baz: "%NULLVALUE%; %NULLVALUE%"},
        # rubocop:enable Layout/LineLength
        #   {foo: nil, bar: " ;%NULLVALUE%", baz: nil},
        # ]
        # ```
        #
        # ### With Array of `treat_as_null` values
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a| b', bar: ' | ', baz: ''},
        #   {foo: nil, bar: '|', baz: ' |b'},
        # rubocop:todo Layout/LineLength
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%|%NULLVALUE%", baz: "%NULLVALUE%| %NULLVALUE%"},
        # rubocop:enable Layout/LineLength
        #   {foo: '%NULL%', bar: "%NULL% |%NULLVALUE%", baz: "%NULL%| %NULL%"},
        # ]
        # ```
        #
        # Setup:
        #
        # ```
        # rubocop:todo Layout/LineLength
        # transform Delete::DelimiterOnlyFieldValues, treat_as_null: ['%NULL%', '%NULLVALUE%']
        # rubocop:enable Layout/LineLength
        # ```
        #
        # Result:
        #
        # ```
        # [
        #   {foo: 'a| b', bar: nil, baz: nil},
        #   {foo: nil, bar: nil, baz: ' |b'},
        #   {foo: nil, bar: nil, baz: nil},
        #   {foo: nil, bar: nil, baz: nil}
        # ]
        # ```
        class DelimiterOnlyFieldValues
          include Allable

          # rubocop:todo Layout/LineLength
          # @param fields [:all, Symbol, Array(Symbol)] in which to delete delimiter-only-values. See
          # rubocop:enable Layout/LineLength
          #   {Transforms} for more on fields parameter.
          # @param delim [String]
          # rubocop:todo Layout/LineLength
          # @param treat_as_null [nil, String, Array(String)] values to treat as though they were null in
          # rubocop:enable Layout/LineLength
          #   determining whether to delete the field value or not
          def initialize(fields: :all, delim: Kiba::Extend.delim,
            treat_as_null: nil)
            @fields = [fields].flatten
            @delim = delim
            @treat_as_null = treat_as_null
            @checker = Helpers::DelimOnlyChecker.new(delim: delim,
              treat_as_null: treat_as_null)
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            finalize_fields(row) unless fields_set
            process_fields(row)
            row
          end

          private

          attr_reader :fields, :checker

          def process_field(field, row)
            val = row[field]
            row[field] = nil if checker.call(val)
          end

          def process_fields(row)
            fields.each { |field| process_field(field, row) }
          end
        end
      end
    end
  end
end
