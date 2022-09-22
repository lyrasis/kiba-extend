# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete

        # Removes fields/columns that contain no values. Supports treating `Kiba::Extend.nullvalue` as an empty value.
        #   Also supports specifying field-specific values that should be treated as though they are empty.
        #
        # @note This transform runs in memory, so for very large sources, it may take a long time or fail.
        #
        # # Examples
        #
        # The examples demonstrating `usenull` assume `Kiba::Extend.nullvalue` is set to `%NULLVALUE%`.
        #
        # ## Basic usage
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::EmptyFields
        # ```
        #
        # Input table:
        #
        # ```
        # | a   | b   | c   | d   |
        # |-----+-----+-----+-----|
        # | a   |     | ccc |     |
        # |     | nil | c   | nil |
        # | nil |     | ccc |     |
        # | a   |     |     |     |
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | c   |
        # |-----+-----|
        # | a   | ccc |
        # |     | c   |
        # | nil | ccc |
        # | a   |     |
        # ```
        #
        # ### Notes
        # Empty strings and nil values are treated as empty by default.
        #
        # ## With usenull true
        #
        # Used in pipeline as:
        #
        # ```
        # transform Delete::EmptyFields, usenull: true
        # ```
        #
        # Input table:
        #
        # ```
        # | a   | b   | c   | d   | e           |
        # |-----+-----+-----+-----+-------------|
        # |     | nil | c   | nil | %NULLVALUE% |
        # | a   |     | ccc |     |             |
        # | nil |     | ccc |     | %NULLVALUE% |
        # | a   |     |     |     |             |
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | c   |
        # |-----+-----|
        # |     | c   |
        # | a   | ccc |
        # | nil | ccc |
        # | a   |     |
        # ```
        #
        # ## With consider_blank config given
        # Used in pipeline as:
        #
        # ```
        # transform Delete::EmptyFields, consider_blank: {b: 'false', c: 'nope', e: "0#{Kiba::Extend.delim}false"}
        # ```
        #
        # Input table:
        #
        # ```
        # | a   | b     | c           | d   | e     |
        # |-----+-------+-------------+-----+-------|
        # |     | nil   |             | nil | 0     |
        # | a   |       | %NULLVALUE% |     | false |
        # | nil | false | nope        |     | 0     |
        # | a   |       | nil         |     |       |
        # ```
        #
        # Results in:
        #
        # ```
        # | a   | c           |
        # |-----+-------------|
        # |     |             |
        # | a   | %NULLVALUE% |
        # | nil | nope        |
        # | a   | nil         |
        # ```
        #
        # ### Notes
        # Field `c` is retained because `usenull: true` is not used. If that argument were given, only Field `a` would be returned.
        #
        class EmptyFields
          # @param usenull [Boolean] whether to treat `Kiba::Extend.nullvalue` as empty/blank value
          # @param consider_blank [Hash{Symbol=>Array<String>}] specifies field-specific value(s) that should be treated
          #   as blank/empty. **If multiple values should be considered blank for one field, join them using
          #   `Kiba::Extend.delimiter`**
          def initialize(usenull: false, consider_blank: nil)
            @usenull = usenull
            @consider_blank = consider_blank ? consider_blank.transform_values{ |val| val.split(Kiba::Extend.delim) } : nil
            @pop_fields = {}
            @rows = []
          end

          # @param row [Hash{ Symbol => String }]
          def process(row)
            populate_tracker(row)
            nil
          end

          def close
            to_delete = rows.first.keys - pop_fields.keys
            rows.each do |row|
              to_delete.each{ |field| row.delete(field) }
              yield row
            end
          end
          
          private

          attr_reader :pop_fields, :rows, :usenull, :consider_blank

          def populate_tracker(row)
            prepare(row).each{ |field, val| pop_fields[field] = nil unless val.blank? }
            rows << row
          end

          def prepare(row)
            return row unless usenull || consider_blank
            
            strip_consider_blanks(strip_nulls(row.dup))
          end

          def strip_consider_blanks(row)
            return row unless consider_blank

            consider_blank.each do |field, blank_vals|
              row[field] = '' if blank_vals.any?(row[field])
            end
            row
          end
          
          def strip_nulls(row)
            return row unless usenull
            
            row.transform_values{ |val| Helpers.empty?(val, usenull) ? '' : val }
          end
        end
      end
    end
  end
end

