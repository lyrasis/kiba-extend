# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Explode

        # Splits given field value on given delimiter. Original row is removed. One new row per split value is added.
        #   Value of split field is one of the split values per row. All other values in row are left the same
        #
        # # Examples
        #
        # Input table:
        # ```
        # | r1  | r2      |
        # |-----+---------|
        # | a;b | foo;bar |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Explode::RowsFromMultivalField, field: :r1, delim: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | r1 | r2      |
        # |----+---------|
        # | a  | foo;bar |
        # | b  | foo;bar |
        # ```
        #
        class RowsFromMultivalField
          # @param field [Symbol] the field from which rows will be created
          # @param delim [String] used to split `field` value
          def initialize(field:, delim:)
            @field = field
            @delim = delim
          end

          # @private
          def process(row)
            other_fields = row.keys.reject { |k| k == field }
            fieldval = row.fetch(field, nil)
            fieldval = fieldval.nil? ? [] : fieldval.split(delim)
            if fieldval.size > 1
              fieldval.each do |val|
                rowcopy = row.clone
                other_fields.each { |f| rowcopy[f] = rowcopy.fetch(f, nil) }
                rowcopy[field] = val
                yield(rowcopy)
              end
              nil
            else
              row
            end
          end

          private

          attr_reader :field, :delim
        end
      end
    end
  end
end
