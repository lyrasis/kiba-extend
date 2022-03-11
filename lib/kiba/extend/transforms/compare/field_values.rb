# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Compare
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
        #  transform Compare::FieldValues, field: :name, target: :ct, delim: ';'
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
        #  transform Compare::FieldValues, field: :name, target: :ct, delim: ';', count_empty: true
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
        #  transform Compare::FieldValues, field: :name, target: :ct, delim: ';', placeholder: 'NULL'
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
        #  transform Compare::FieldValues, field: :name, target: :ct, delim: ';', placeholder: 'NULL', count_empty: true
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
          # @param fields [Array<Symbol>] names of fields whose values will be compared
          # @param target [Symbol] new field in which to record comparison result
          # @param downcase [Boolean] whether to downcase all values for comparison. `false` results in a case sensitive
          #   comparison. `true` results in a case insensitive comparison.
          # @param strip [Boolean] whether to remove leading/trailing spaces prior to comparison
          # @param ignore_blank [Boolean] `true` drops empty or nil values from the comparison
          def initialize(fields:, target:, downcase: true, strip: true, ignore_blank: false)
            @fields = [fields].flatten
            @target = target
            @strip = strip
            @downcase = downcase
            @ignore_blank = ignore_blank
          end

          # @private
          def process(row)
            row[@target] = 'diff'
            values = []
            @fields.each do |field|
              value = row.fetch(field, '').dup
              value = '' if value.nil?
              value = value.downcase if @downcase
              value = value.strip if @strip
              values << value
            end
            values.reject!(&:blank?) if @ignore_blank
            row[@target] = 'same' if values.uniq.length == 1 || values.empty?
            row
          end
        end
      end
    end
  end
end
