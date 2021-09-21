# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      # Transformations which significantly change the shape of the data without adding new rows.
      #
      # See {Kiba::Extend::Transforms::Explode} for transformations that change the shape and add new rows.
      module Reshape
        ::Reshape = Kiba::Extend::Transforms::Reshape

        # Takes multiple fields like :workphone, :homephone, :mobilephone and produces two new fields like :phone and :phonetype where :phonetype depends on the original field taken from
        #
        # # Examples
        #
        # Input table:
        #
        # ```
        # | work | home     | mobile | other | name |
        # |------+----------+--------+-------+------|
        # | 123  | 456      | 789    | 897   | Sue  |
        # |      | 987;555  |        | 253   | Bob  |
        # | nil  |          |        | nil   | Mae  |
        # | 654  | 321      | 257    |       | Sid  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
        #    sourcefieldmap: { home: 'h', work: 'b', mobile: 'm', other: '' },
        #    datafield: :phone,
        #    typefield: :phonetype,
        #    sourcesep: ';',
        #    targetsep: '^',
        #    delete_sources: false
        # ```
        #
        # Results in:
        #
        # ```
        # | work | home     | mobile | other | phone           | phonetype | name |
        # |------+----------+--------+-------|-----------------+-----------+------|
        # | 123  | 456      | 789    | 897   | 456^123^789^897 | h^b^m^    | Sue  |
        # |      | 987;555  |        | 253   | 987^555^253     | h^h^      | Bob  |
        # | nil  |          |        | nil   | nil             | nil       | Mae  |
        # | 654  | 321      | 257    |       | 321^654^257     | h^b^m     | Sid  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #  transform Reshape::CollapseMultipleFieldsToOneTypedFieldPair,
        #    sourcefieldmap: { home: 'h', work: 'b', mobile: '', other: 'o' },
        #    datafield: :phone,
        #    typefield: :phonetype,
        #    targetsep: '^'
        # ```
        #
        # Results in:
        #
        # ```
        # | phone           | phonetype | name |
        # |-----------------+-----------+------|
        # | 456^123^789^897 | h^b^m^    | Sue  |
        # | 987;555^253     | h^        | Bob  |
        # | nil             | nil       | Mae  |
        # | 321^654^257     | h^b^m     | Sid  |
        # ```
        #
        # ## Notice
        #
        # * The number of values in `phone` and `phonetype` are kept even
        # * The data in the target fields is in the order of the keys in the `sourcefieldmap`: home, work, mobile, other.
        class CollapseMultipleFieldsToOneTypedFieldPair
          # @param sourcefieldmap [Hash{Symbol => String}] Keys are the names of the source fields. Each key's value is the type that should be assigned in `typefield`
          # @param datafield [Symbol] Target field into which the original data value(s) from source fields will be mapped
          # @param typefield [Symbol] Target field into which the type values will be mapped
          # @param sourcesep [String] Delimiter used to split source data into multiple values
          # @param targetsep [String] Delimiter used to join multiple values in target fields
          # @param delete_sources [Boolean] Whether to delete source fields after mapping them to target fields
          def initialize(sourcefieldmap:, datafield:, typefield:, targetsep:, sourcesep: nil, delete_sources: true)
            @map = sourcefieldmap
            @df = datafield
            @tf = typefield
            @sourcesep = sourcesep
            @targetsep = targetsep
            @del = delete_sources
          end

          # @private
          def process(row)
            data = []
            type = []
            @map.each_key do |sourcefield|
              vals = row.fetch(sourcefield)
              unless vals.nil?
                vals = @sourcesep.nil? ? [vals] : vals.split(@sourcesep)
                vals.each do |val|
                  data << val
                  type << @map.fetch(sourcefield, @default_type)
                end
              end
              row.delete(sourcefield) if @del
            end
            row[@df] = data.size.positive? ? data.join(@targetsep) : nil
            row[@tf] = type.size.positive? ? type.join(@targetsep) : nil
            row
          end
        end

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

          # @private
          def process(row)
            gather_column_field(row)
            nil
          end

          # @private
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
