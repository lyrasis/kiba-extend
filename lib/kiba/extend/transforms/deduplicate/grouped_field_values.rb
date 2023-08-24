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
        # @example Basic usage/defaults
        #   # Used in pipeline as:
        #   # transform Deduplicate::GroupedFieldValues,
        #   #   on_field: :name,
        #   #   grouped_fields: %i[work role],
        #   #   delim: ';'
        #   xform = Deduplicate::GroupedFieldValues.new(
        #     on_field: :name,
        #     grouped_fields: %i[work role],
        #     delim: ';'
        #   )
        #   input = [
        #     # empty/delim-only values in :on_field
        #     {name: ';',
        #      work: ';',
        #      role: 'auth;ed'},
        #     # nil value in :on_field
        #     {name: nil,
        #      work: 'auth;ed',
        #      role: ';'},
        #     # nil value in other field
        #     {name: 'Jan;Jan',
        #      work: nil,
        #      role: 'auth;ed'},
        #     # role has empty value for Jan
        #     {name: 'Bob;Jan;Bob',
        #      work: ';',
        #      role: 'auth;;ctb'},
        #     # work is empty string value; role has only 2 values
        #     {name: 'Cam;Jan;Cam',
        #      work: '',
        #      role: 'auth;ed'},
        #     # lots of values, multiple duplicates
        #     {name: 'Fred;Jan;Fred;Bob;Fred;Bob',
        #      work: 'Rpt;Bk;Paper;Bk;Pres;Bk',
        #      role: 'auth;photog;ed;ill;auth;ed.'},
        #     # single value
        #     {name: 'Martha',
        #      work: 'Bk',
        #      role: 'ctb'}
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     # empty string values returned as nil values
        #     {name: nil,
        #      work: nil,
        #      role: 'auth'},
        #     # no processing possible, row passed through
        #     {name: nil,
        #      work: 'auth;ed',
        #      role: ';'},
        #     # nil values not processed
        #     {name: 'Jan',
        #      work: nil,
        #      role: 'auth'},
        #     # empty string values to be concatenated are treated as such
        #     {name: 'Bob;Jan',
        #      work: nil,
        #      role: 'auth;'},
        #     # empty string -> nil, role not having a 3rd value to delete does
        #     #   not cause failure or weirdness
        #     {name: 'Cam;Jan',
        #      work: nil,
        #      role: 'auth;ed'},
        #     # keeps first value associated with each name
        #     {name: 'Fred;Jan;Bob',
        #      work: 'Rpt;Bk;Bk',
        #      role: 'auth;photog;ill'},
        #     # passes row through; nothing to deduplicate
        #     {name: 'Martha',
        #      work: 'Bk',
        #      role: 'ctb'}
        #   ]
        #   expect(result).to eq(expected)
        # @example Case insensitive deduplication
        #   xform = Deduplicate::GroupedFieldValues.new(
        #     on_field: :name,
        #     grouped_fields: %i[work role],
        #     delim: ';',
        #     ignore_case: true
        #   )
        #   input = [
        #     {name: 'Jan;jan',
        #      work: nil,
        #      role: 'auth;ed'},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: 'Jan',
        #      work: nil,
        #      role: 'auth'},
        #   ]
        #   expect(result).to eq(expected)
        # @example Normalized deduplication
        #   xform = Deduplicate::GroupedFieldValues.new(
        #     on_field: :role,
        #     grouped_fields: %i[name],
        #     delim: ';',
        #     normalized: true
        #   )
        #   input = [
        #     {name: 'Jan;Bob;Sam;Pat;Hops',
        #      role: 'auth./ill.;auth, ill;ed;ed.;Ed.'},
        #   ]
        #   result = input.map{ |row| xform.process(row) }
        #   expected = [
        #     {name: 'Jan;Sam;Hops',
        #      role: 'auth./ill.;ed;Ed.'},
        #   ]
        #   expect(result).to eq(expected)
        class GroupedFieldValues
          include SepDeprecatable
          # @param on_field [Symbol] the field we deduplicating (comparing, and
          #   initially removing values from
          # @param sep [nil, String] **DEPRECATED** do not use in new transforms
          # @param delim [nil, String] used to split/join multivalued field
          #   values
          # @param grouped_fields [Array<Symbol>] other field(s) in the same
          #   multi-field grouping as `field`. Values will be removed from these
          #   fields **positionally**, if the corresponding value was removed
          #   from `field`
          # @param ignore_case [Boolean]
          # @param normalized [Boolean] if true, will apply
          #   {Kiba::Extend::Utils::StringNormalizer} with arguments:
          #   `mode: :plain, downcased: false` to values for comparison
          def initialize(on_field:, sep: nil, delim: nil, grouped_fields: [],
            ignore_case: false, normalized: false)
            @field = on_field
            @other = grouped_fields
            @delim = usedelim(sepval: sep, delimval: delim, calledby: self)
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: grouped_fields,
              discard: %i[nil]
            )
            @ignore_case = ignore_case
            if normalized
              @normalizer = Utils::StringNormalizer.new(downcased: false)
            end
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            val = row[field]
            return row if val.blank?

            vals = comparable_values(row)

            to_delete = deletable_elements(vals)
            return row if to_delete.empty?

            do_deletes(row, to_delete)

            row
          end

          private

          attr_reader :field, :other, :delim, :getter, :ignore_case, :normalizer

          def comparable_values(row)
            val = row[field]
            return [] if val.blank?

            vals = val.split(delim, -1)
            cased = ignore_case ? vals.map(&:downcase) : vals
            if normalizer
              cased.map { |val| normalizer.call(val) }
            else
              cased
            end
          end

          def delete_values(arr, to_delete)
            to_delete.each { |idx| arr.delete_at(idx) }
            arr.empty? ? nil : arr.join(delim)
          end

          def field_deletes(row, to_delete)
            vals = row[field]
              .split(delim)
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
              .each { |fld| row[fld] = nil }
          end

          def other_deletes(row, to_delete, fld, val)
            vals = val.split(delim)
            row[fld] = delete_values(vals, to_delete)
          end
        end
      end
    end
  end
end
