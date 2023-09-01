# frozen_string_literal: true

# rubocop:todo Layout/LineLength

module Kiba
  module Extend
    module Transforms
      # Transformations that extract specified data from a source
      # @since 2.2.0
      module Extract
        ::Extract = Kiba::Extend::Transforms::Extract

        # Extracts the values of the given fields to a single `:value` column
        #
        # Inserts a `:from_field` column recording original field name for the value
        #   in each row. This can be turned off, resulting in a single-column result.
        #
        # Optionally, if given `:sep` value, splits multi-val fields to separate rows.
        #
        # @note This will collapse any source data to a one or two column result. It runs in-memory,
        #   so for very large sources, it may take a long time or fail
        #
        # Input table:
        #
        # ```
        # | foo | bar | baz | boo|
        # |----------------------|
        # | a:b | e   | f   |    |
        # | c   | nil | g   | h  |
        # | :d  | i:  | j   | k  |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Extract::Fields, fields: %i[foo bar], sep: ':'
        # ```
        #
        # Results in:
        #
        # ```
        # | value | from_field |
        # |--------------------|
        # | a     | foo        |
        # | b     | foo        |
        # | e     | bar        |
        # | c     | foo        |
        # | d     | foo        |
        # | i     | bar        |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Extract::Fields, fields: %i[foo bar], source_field_track: false
        # ```
        #
        # Results in:
        #
        # ```
        # | value |
        # |--------
        # | a:b   |
        # | e     |
        # | c     |
        # | :d    |
        # | i:    |
        # ```
        class Fields
          def initialize(fields:, sep: nil, source_field_track: true)
            @fields = [fields].flatten
            @sep = sep
            @track = source_field_track
            @rows = []
          end

          def process(row)
            @fields.each { |field| extract_field_value(row, field) }
            nil
          end

          def close
            @rows.each { |row| yield row }
          end

          private

          def extract_field_value(row, field)
            field_val = row.fetch(field, nil)
            return if field_val.blank?

            vals = @sep ? field_val.split(@sep) : [field_val]
            vals.each do |val|
              next if val.blank?

              new_row = @track ? {value: val,
                                  from_field: field} : {value: val}
              @rows << new_row
            end
          end
        end
      end
    end
  end
end
# rubocop:enable Layout/LineLength
