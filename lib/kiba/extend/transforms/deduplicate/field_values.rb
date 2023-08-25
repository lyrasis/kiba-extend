# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Removes duplicate values within the given field(s)
        #
        # rubocop:todo Layout/LineLength
        # Processes one field at a time. Splits value on sep, and keeps only the unique values
        # rubocop:enable Layout/LineLength
        #
        # rubocop:todo Layout/LineLength
        # @note This is NOT safe for use with groupings of fields whose multi-values are expected
        # rubocop:enable Layout/LineLength
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
          # rubocop:todo Layout/LineLength
          # @param fields [Array<Symbol>] names of fields in which to deduplicate values
          # rubocop:enable Layout/LineLength
          # @param sep [String] used to split/join multivalued field values
          def initialize(fields:, sep:)
            @fields = [fields].flatten
            @sep = sep
          end

          # @param row [Hash{ Symbol => String, nil }]
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
