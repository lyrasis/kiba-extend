# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Field value deduplication that is at least semi-safe for use with
        #   grouped fields that expect the same number of values for each field
        #   in the grouping
        #
        # @note Tread with caution, as this has not been used much and is not
        #   extensively tested
        #
        #
        # Input table:
        #
        # ```
        # | name                  | work                   | role                                   |
        # |-----------------------+------------------------+----------------------------------------|
        # | Fred;Freda;Fred;James | Report;Book;Paper;Book | author;photographer;editor;illustrator |
        # | ;                     | ;                      | ;                                      |
        # | Martha                | Book                   | contributor                            |
        # ```
        #
        # Used in pipeline as:
        #
        # ```
        # transform Deduplicate::GroupedFieldValues,
        #   on_field: :name,
        #   grouped_fields: %i[work role],
        #   sep: ';'
        # ```
        #
        # Results in:
        #
        # ```
        # | name             | work             | role                            |
        # |------------------+------------------+---------------------------------|
        # | Fred;Freda;James | Report;Book;Book | author;photographer;illustrator |
        # | nil              | nil              | nil                             |
        # | Martha           | Book             | contributor                     |
        # ```
        #
        class GroupedFieldValues
          # @param on_field [Symbol] the field we deduplicating (comparing, and
          #   initially removing values from
          # @param sep [String] used to split/join multivalued field values
          # @param grouped_fields [Array<Symbol>] other field(s) in the same
          #   multi-field grouping as `field`. Values will be removed from these
          #   fields **positionally**, if the corresponding value was removed
          #   from `field`
          def initialize(on_field:, sep:, grouped_fields: [])
            @field = on_field
            @other = grouped_fields
            @sep = sep
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: grouped_fields,
              discard: %i[nil]
            )
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            vals = comparable_values(row)
            if vals.empty? || vals.all?{ |v| v.empty? }
              null_fields(row)
            else
              to_delete = deletable_elements(vals)
              return row if to_delete.empty?

              do_deletes(row, to_delete)
            end
            row
          end

          private

          attr_reader :field, :other, :sep, :getter

          def comparable_values(row)
            val = row[field]
            return [] if val.blank?

            val.split(sep, -1)
          end

          def delete_values(arr, to_delete)
            to_delete.each{ |idx| arr.delete_at(idx) }
            arr.empty? ? nil : arr.join(sep)
          end

          def field_deletes(row, to_delete)
            vals = row[field]
              .split(sep)
            row[field] = delete_values(vals, to_delete)
          end

          def do_deletes(row, to_delete)
            field_deletes(row, to_delete)
            others = getter.call(row)
            return if others.empty?

            others.each do |fld, val|
              other_deletes(row, to_delete, fld, val)
            end
          end

          def deletable_elements(arr)
            return [] if arr.empty?

            to_delete = []
            keeping = []

            arr.each_with_index do |val, idx|
              keeping.any?(val) ? to_delete << idx : keeping << val
            end
            to_delete.sort.reverse
          end

          def null_fields(row)
            [field, other].flatten
              .each{ |fld| row[fld] = nil }
          end

          def other_deletes(row, to_delete, fld, val)
            vals = val.split(sep)
            row[fld] = delete_values(vals, to_delete)
          end
        end
      end
    end
  end
end
