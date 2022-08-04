# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Count
        # Adds the given field(s) to the row with nil value if they do not already exist in row
        #
        # # Examples
        #
        # Input table is not shown separately. It is just `name` column of the results tables shown below. The blank
        #   value in name indicates an empty Ruby String object. The nil indicates a Ruby NilValue object.
        #
        # ## Example 1
        # No placeholder value is given, so "NULL" is treated as a string value. `count_empty` defaults to false, so
        #   empty values are not counted.
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Count::FieldValues, field: :name, target: :ct, delim: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | ct |
        # |----------------------+----|
        # | Weddy                | 1  |
        # | NULL                 | 1  |
        # |                      | 0  |
        # | nil                  | 0  |
        # | Earlybird;Divebomber | 2  |
        # | ;Niblet              | 1  |
        # | Hunter;              | 1  |
        # | NULL;Earhart         | 2  |
        # | ;                    | 0  |
        # | NULL;NULL            | 2  |
        # ```
        #
        # ## Example 2
        # No placeholder value is given, so "NULL" is treated as a string value. `count_empty` is true, so
        #   empty values are counted. Note that fully empty field values are not counted, but when a
        #   delimiter is present, any empty values delimited by it are counted.
        #
        # These options are functionally equivalent to those shown in example 4.
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Count::FieldValues, field: :name, target: :ct, delim: ';', count_empty: true
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | ct |
        # |----------------------+----|
        # | Weddy                | 1  |
        # | NULL                 | 1  |
        # |                      | 0  |
        # | nil                  | 0  |
        # | Earlybird;Divebomber | 2  |
        # | ;Niblet              | 2  |
        # | Hunter;              | 2  |
        # | NULL;Earhart         | 2  |
        # | ;                    | 2  |
        # | NULL;NULL            | 2  |
        # ```
        #
        # ## Example 3
        # Placeholder value is given, so "NULL" is treated as an empty value. `count_empty` default to false, so empty
        #   values, including any values that equal the given placeholder value, are not counted.
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Count::FieldValues, field: :name, target: :ct, delim: ';', placeholder: 'NULL'
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | ct |
        # |----------------------+----|
        # | Weddy                | 1  |
        # | NULL                 | 0  |
        # |                      | 0  |
        # | nil                  | 0  |
        # | Earlybird;Divebomber | 2  |
        # | ;Niblet              | 1  |
        # | Hunter;              | 1  |
        # | NULL;Earhart         | 1  |
        # | ;                    | 0  |
        # | NULL;NULL            | 0  |
        # ```
        #
        # ## Example 4
        # Placeholder value is given, so "NULL" is treated as an empty value. `count_empty` is true, so
        #   empty values are counted. Note that fully empty field values are not counted, but when a
        #   delimiter is present, any empty values delimited by it are counted.
        #
        # These options are functionally equivalent to those shown in example 2.
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Count::FieldValues, field: :name, target: :ct, delim: ';', placeholder: 'NULL', count_empty: true
        # ```
        #
        # Results in:
        #
        # ```
        # | name                 | ct |
        # |----------------------+----|
        # | Weddy                | 1  |
        # | NULL                 | 1  |
        # |                      | 0  |
        # | nil                  | 0  |
        # | Earlybird;Divebomber | 2  |
        # | ;Niblet              | 2  |
        # | Hunter;              | 2  |
        # | NULL;Earhart         | 2  |
        # | ;                    | 2  |
        # | NULL;NULL            | 2  |
        # ```
        class FieldValues
          # @param field [Symbol] the field whose values should be counted
          # @param target [Symbol] new field in which to record counts
          # @param delim [String] value used to split
          # @param placeholder [String, NilValue] string that acts as a placeholder for empty value. If nil,
          #   nothing is used as a placeholder
          # @param count_empty [Boolean] whether empty placeholder values should be counted
          def initialize(field:, target:, delim: Kiba::Extend.delim, placeholder: nil, count_empty: false)
            @field = field
            @target = target
            @delim = delim
            @placeholder = placeholder
            @count_empty = count_empty
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            row[@target] = '0'
            val = row.fetch(@field, nil)
            return row unless val

            split = val.split(@delim, -1)
            to_count = handle_empty(split)
            row[@target] = to_count.length.to_s
            row
          end

          private

          def handle_empty(vals)            
            with_placeholder = handle_placeholder(vals)
            return with_placeholder if @count_empty

            with_placeholder.reject(&:empty?)
          end

          def handle_placeholder(vals)
            return vals unless @placeholder

            vals.map{ |val| val.sub(/^#{@placeholder}$/, '') }
          end
        end
      end
    end
  end
end
