# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Removes duplicate values within the given field(s)
        #
        # Processes one field at a time. Splits value on sep, and keeps only the unique values
        #
        # @note This is NOT safe for use with groupings of fields whose multi-values are expected
        #   to be the same length
        #
        # Input table:
        # 
        # ```
        # | foo         | bar       |
        # |-------------------------|
        # | 1;1;1;2;2;2 | a;A;b;b;b |
        # |             | q;r;r     |
        # | 1           | 2         |
        # | 1           | 2         |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        #   @deduper = {}
        #   transform Deduplicate::FieldValues, fields: %i[foo bar], sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | foo   | bar     |
        # |-----------------|
        # | 1;2   | a;A;b   |
        # |       | q;r     |
        # | 1     | 2       |
        # | 1     | 2       |
        # ```
        #
        class FieldValues
          # @param fields [Array<Symbol>] names of fields in which to deduplicate values
          # @param sep [String] used to split/join multivalued field values
          def initialize(fields:, sep:)
            @fields = [fields].flatten
            @sep = sep
          end

          # @private
          def process(row)
            @fields.each do |field|
              val = row.fetch(field)
              row[field] = val.to_s.split(@sep).uniq.join(@sep) unless val.nil?
            end
            row
          end
        end
      end
    end
  end
end
