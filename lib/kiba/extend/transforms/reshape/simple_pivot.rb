# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Reshape
        # Dynamically pivots your data into a new shape, based on values of the given fields.

        # @note This transformation runs in memory, so it may bog down or crash on extremely large
        #   data sources
        # @note This transformation has some pretty strong assumptions and limitations that can be
        #   quite destructive, so examine the example below carefully.
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | authority | norm    | term        | unrelated |
        # |-----------+---------+-------------+-----------|
        # | person    | fred    | Fred Q.     | foo       |
        # | org       | fred    | Fred, Inc.  | bar       |
        # | location  | unknown | Unknown     | baz       |
        # | person    | unknown | Unknown     | fuz       |
        # | org       | unknown | Unknown     | aaa       |
        # | work      | book    | Book        | eee       |
        # | location  | book    |             | zee       |
        # |           | book    | Book        | squeee    |
        # | nil       | ghost   | Ghost       | boo       |
        # | location  |         | Ghost       | zoo       |
        # | location  | ghost   | nil         | poo       |
        # | org       | fred    | Fred, Corp. | bar       |
        # | issues    | nil     | nil         | bah       |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Reshape::SimplePivot,
        #   field_to_columns: :authority,
        #   field_to_rows: :norm,
        #   field_to_col_vals: :term
        # ```
        #
        # Results in:
        #
        # ```
        # | norm    | person  | org         | location | work | issues |
        # |---------+---------+-------------+----------+------+--------|
        # | fred    | Fred Q. | Fred, Corp. | nil      | nil  | nil    |
        # | unknown | Unknown | Unknown     | Unknown  | nil  | nil    |
        # | book    | nil     | nil         | nil      | Book | nil    |
        # ```
        #
        # **NOTE**
        #
        # - A new column has been created for each unique value in the `field_to_columns` field
        # - A single row has been generated for each unique value in the `field_to_rows` field
        # - The value from the `field_to_col_vals` field is in the appropriate column
        # - When more than one row has the same values for `field_to_columns` and `field_to_rows`,
        #   the value of the last row processed's `field_to_col_vals` will be used (we get Fred, Corp.
        #   instead of Fred, Inc.
        # - Only data from the three involved fields is kept! Note that the `unrelated` field from
        #   the input has been lost
        # - Rows lacking a value for any of the three fields will be skipped, in terms of populating
        #   the dynamically created column (see the Ghost examples)
        # - However, a dynamically created column will still be created even if it is given no data
        #   (See issues example)
        class SimplePivot
          # @param field_to_columns [Symbol] field whose values will generate new columns
          # @param field_to_rows [Symbol] field whose values will generate the result rows (data is collapsed on
          #   values in this field)
          # @param field_to_col_vals [Symbol] field whose values get put in the new columns per row
          def initialize(field_to_columns:, field_to_rows:, field_to_col_vals:)
            @col_field = field_to_columns
            @row_field = field_to_rows
            @col_val_field = field_to_col_vals
            @rows = {}
            @columns = {}
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            gather_column_field(row)
            nil
          end

          def close
            @rows.each do |fieldval, data|
              row = {@row_field => fieldval}
              row = row.merge(data)
              row_fields = row.keys.freeze
              @columns.keys.each{ |field| row[field] = nil unless row_fields.any?(field) }
              yield row
            end
          end

          private

          def gather_column_field(row)
            col_value = row.fetch(@col_field, nil)
            return if col_value.blank?

            col_name = col_value.to_sym
            @columns[col_name] = nil
            record_column_value_for_row(row, col_name)
          end

          def record_column_value_for_row(row, column)
            row_field_val = row.fetch(@row_field, nil)
            col_val = row.fetch(@col_val_field, nil)
            return if row_field_val.blank? || col_val.blank?

            @rows[row_field_val] = {} unless @rows.keys.any?(row_field_val)
            @rows[row_field_val][column] = col_val
          end
        end
      end
    end
  end
end
