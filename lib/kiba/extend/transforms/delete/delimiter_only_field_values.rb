# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # @since 2.9.0
        #
        # Converts any value in given field(s) to nil if that value is `empty?`, or consists only
        #   of the specified delimiter, `treat_as_null` value(s), and, optionally, spaces.
        #
        # See also {Kiba::Extend::Transforms::Helpers::DelimOnlyChecker}, which is used by this transform.
        #
        # ## Examples
        #
        # ### Default
        #
        # Deletes delimiter-only field values from all fields. No strings except `''` (empty string) are
        #   treated as null. **This assumes your project has set `Kiba::Extend.delim` to equal `|`.**
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a| b', bar: ' | ', baz: ''},
        #   {foo: nil, bar: '|', baz: ' |b'},
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%|%NULLVALUE%", baz: "%NULLVALUE%| %NULLVALUE%"},
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
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%|%NULLVALUE%", baz: "%NULLVALUE%| %NULLVALUE%"},
        #   {foo: 'NULL', bar: "NULL |%NULLVALUE%", baz: "NULL| NULL"},
        # ]
        # ```
        #
        # ### With non-default `delim` and `treat_as_null` parameters
        #
        # > **NOTE**: The replacements done to determine whether or not a value is delimiter-only are not
        #   applied to the remaining field values. Otherwise, we'd see the `%NULLVALUE%`s in the results
        #   transformed to `%VALUE%`.
        #
        # Source data:
        #
        # ```
        # [
        #   {foo: 'a; b', bar: ' ; ', baz: ''},
        #   {foo: nil, bar: ';', baz: ' ;b'},
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%;%NULLVALUE%", baz: "%NULLVALUE%; %NULLVALUE%"},
        #   {foo: 'NULL', bar: "NULL ;%NULLVALUE%", baz: "NULL; NULL"},
        # ]
        # ```
        #
        # Setup:
        #
        # ```
        # transform Delete::DelimiterOnlyFieldValues, delim: ';', treat_as_null: 'NULL'
        # ```
        #
        # Result:
        #
        # ```
        # [
        #   {foo: 'a; b', bar: nil, baz: nil},
        #   {foo: nil, bar: nil, baz: ' ;b'},
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%;%NULLVALUE%", baz: "%NULLVALUE%; %NULLVALUE%"},
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
        #   {foo: %NULLVALUE%, bar: "%NULLVALUE%|%NULLVALUE%", baz: "%NULLVALUE%| %NULLVALUE%"},
        #   {foo: '%NULL%', bar: "%NULL% |%NULLVALUE%", baz: "%NULL%| %NULL%"},
        # ]
        # ```
        #
        # Setup:
        #
        # ```
        # transform Delete::DelimiterOnlyFieldValues, treat_as_null: ['%NULL%', '%NULLVALUE%']
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
          
          # @param fields [:all, Symbol, Array(Symbol)] in which to delete delimiter-only-values. See
          #   {Transforms} for more on fields parameter.
          # @param delim [String]
          # @param treat_as_null [nil, String, Array(String)] values to treat as though they were null in
          #   determining whether to delete the field value or not
          def initialize(fields: :all, delim: Kiba::Extend.delim, treat_as_null: nil)
            @fields = [fields].flatten
            @delim = delim
            @treat_as_null = treat_as_null
            @checker = Helpers::DelimOnlyChecker.new(delim: delim, treat_as_null: treat_as_null)
          end

          # @param row [Hash{ Symbol => String }]
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
            fields.each{ |field| process_field(field, row) }
          end
        end
      end
    end
  end
end
