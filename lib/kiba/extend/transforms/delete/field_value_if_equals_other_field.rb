# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Delete
        # Deletes value in `delete` field if that value matches value
        #   in `if_equal_to` field. Opinionated treatment of
        #   multivalued fields described below. Case sensitive or
        #   insensitive matching options. Can also delete associated
        #   field values (by position) in additional grouped fields.
        #   This is useful, for example, in maintaining the integrity
        #   of grouped/subgrouped multivalue fields in
        #   CollectionSpace.
        #
        # **Note that the value of the `if_equal_to` field is never modified by
        #   this transform.**
        #
        # @example Simple example
        #   # Used in pipeline as:
        #   # transform Delete::FieldValueIfEqualsOtherField,
        #   #    delete: :del, if_equal_to: :compare
        #   xform = Delete::FieldValueIfEqualsOtherField.new(
        #     delete: :del,
        #     if_equal_to: :compare
        #   )
        #   input = [
        #     {del: "a", compare: "b"},
        #     {del: "c", compare: "c"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {del: "a", compare: "b"},
        #     {del: nil, compare: "c"}
        #   ]
        #   expect(result).to eq(expected)
        #   # Notes
        #   #
        #   # The first row is left alone because a != b.
        #   #
        #   # In the second row, c is deleted from `del` because the value of
        #   #   `compare` is also c.
        #
        # @example Even multival grouped fields, case insensitive
        #   # Used in pipeline as:
        #   # transform Delete::FieldValueIfEqualsOtherField,
        #   #    delete: :del, if_equal_to: :compare, multival: true,
        #   #    delim: ";", grouped_fields: %i[grpa grpb],
        #   #    casesensitive: false
        #   xform = Delete::FieldValueIfEqualsOtherField.new(
        #     delete: :del,
        #     if_equal_to: :compare,
        #     multival: true,
        #     delim: ";",
        #     grouped_fields: %i[grpa grpb],
        #     casesensitive: false
        #   )
        #   input = [
        #     {row: "1", del: "A;C;d;c;e", compare: "c", grpa: "y;x;w;u;v",
        #      grpb: "e;f;g;h;i"},
        #     {row: "2", del: "a;b;c", compare: "a;z;c", grpa: "d;e;f",
        #      grpb: "g;h;i"},
        #     {row: "3", del: "a", compare: "a;b", grpa: "d", grpb: "g"},
        #     {row: "4", del: "a", compare: "b", grpa: "z", grpb: "q"},
        #     {row: "5", del: "a", compare: "a", grpa: "z", grpb: "q"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {row: "1", del: "A;d;e", compare: "c", grpa: "y;w;v",
        #       grpb: "e;g;i"},
        #     {row: "2", del: "b", compare: "a;z;c", grpa: "e", grpb: "h"},
        #     {row: "3", del: nil, compare: "a;b", grpa: nil, grpb: nil},
        #     {row: "4", del: "a", compare: "b", grpa: "z", grpb: "q"},
        #     {row: "5", del: nil, compare: "a", grpa: nil, grpb: nil}
        #   ]
        #   expect(result).to eq(expected)
        #   # ROW 1
        #   # If `compare` is a single value, all individual values in `del`
        #   #   are compared to the single `compare` value.
        #   #
        #   # In `del` field, elements 1 (C) and 3 (c) are case-insensitive
        #   #   matches on the value in `compare`. Thus, elements 1 and 3 are
        #   #   removed from `del` and both grouped fields.
        #   #
        #   # ROW 2
        #   # If `compare` has multiple values, the values of `del` and
        #   #   `compare` are compared positionally.
        #   #
        #   # Element 0 is a match (a in both). Element 1 is not (b != z).
        #   #   Element 2 is a match (c in both).
        #   #
        #   # Elements 0 and 2 are removed `del` and all grouped fields.
        #   #
        #   # ROW 3
        #   # `compare` is multivalued, so `del` is compared positionally
        #   #   against `compare`, though `del` (and the grouped fields) are
        #   #   single valued.
        #   #
        #   # When all values are removed from a field, `nil` is returned.
        #   #
        #   # ROW 4
        #   # a != b, so row is returned unmodified.
        #   #
        #   # ROW 5
        #   # a = a, so a (Element 0) is removed from `del`. Element 0 is then
        #   #   removed from the grouped fields.
        #
        # @example Ragged multival grouped fields, case insensitive
        #   # Used in pipeline as:
        #   # transform Delete::FieldValueIfEqualsOtherField,
        #   #    delete: :del, if_equal_to: :compare, multival: true,
        #   #    delim: ";", grouped_fields: %i[grpa grpb],
        #   #    casesensitive: false
        #   xform = Delete::FieldValueIfEqualsOtherField.new(
        #     delete: :del,
        #     if_equal_to: :compare,
        #     multival: true,
        #     delim: ";",
        #     grouped_fields: %i[grpa grpb],
        #     casesensitive: false
        #   )
        #   input = [
        #     {del: "A;C;d;e;c", compare: "c", grpa: "y;x;w;u",
        #       grpb: "e;f;g;h;i"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {del: "A;d;e", compare: "c", grpa: "y;w;u", grpb: "e;g;h"}
        #   ]
        #   expect(result).to eq(expected)
        #   # This triggers a warning printed to STDOUT, which may trigger you
        #   #   to examine the input data:
        #
        #   # ~~~
        #   # KIBA WARNING: One or more grouped fields (grpa, grpb) has
        #   #   different number of values than the others in {:del=>"A;d;e",
        #   #   :compare=>"c", :grpa=>"y;x;w;u", :grpb=>"e;f;g;h;i"}
        #   # ~~~
        #
        #   # If `del` had 4 elements and one or more of the grouped fields had
        #   #   a different number of elements, this would be handled similarly,
        #   #   with a slightly different warning.
        #
        #   # `grpa` has 4 values, while `grpb` has 5.
        #   #
        #   # Elements 1 and 4 from `del` match `compare`, so they are deleted.
        #   #   Those elements are also deleted from the grouped fields if
        #   #   present.
        class FieldValueIfEqualsOtherField
          # @param delete [Symbol] field from which values will be deleted
          # @param if_equal_to [Symbol] field the `delete` values will be
          #   compared to. In other words, the "other field"
          # @param multival [Boolean] whether to split field values for
          #   comparison
          # @param delim [String] on which to split if `multival`. Defaults to
          #   `Kiba::Extend.delim` if not provided.
          # @param grouped_fields [Array<Symbol>] field(s) from which
          #   positionally corresponding values should also be removed
          # @param casesensitive [Boolean] matching mode
          def initialize(delete:, if_equal_to:, multival: false, delim: nil,
            grouped_fields: [], casesensitive: true)
            @delete = delete
            @compare = if_equal_to
            @multival = multival
            @delim = delim || Kiba::Extend
            @group = grouped_fields
            @casesensitive = casesensitive
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            del_val = prepare_val(delete, row, :compare)
            compare_val = prepare_val(compare, row, :compare)
            return row if compare_val.nil? || del_val.blank?

            compare_method = get_compare_method(del_val, compare_val)
            to_delete = method(compare_method).call(del_val, compare_val)
            return row if to_delete.empty?

            orig_del_val = prepare_val(delete, row, :final)
            row[delete] = do_deletes(to_delete, orig_del_val.dup)
            return row unless grouped?

            grouped = group.map { |field| prepare_val(field, row) }
            validation = validate_groups(grouped, orig_del_val)
            report_group_issue(validation, row) unless validation == :valid
            grouped.map { |grp| do_deletes(to_delete, grp) }
              .each_with_index { |grp, i| row[group[i]] = grp }

            row
          end

          private

          attr_reader :delete, :compare, :multival, :delim, :group,
            :casesensitive

          def prepare_val(field, row, type = :final)
            val = row.fetch(field)
            return nil if val.blank?

            if type == :final
              split = multival ? val.split(delim) : [val]
              return split
            end

            norm_val = casesensitive ? val : val.downcase
            multival ? norm_val.split(delim) : [norm_val]
          end

          def get_compare_method(del_val, compare_val)
            return :compare_against_single_value if compare_val.length == 1

            :compare_against_multi_value
          end

          def compare_against_multi_value(del_val, compare_val)
            to_del = []
            del_val.each_with_index do |val, i|
              to_del << i if val == compare_val[i]
            end
            to_del.sort.reverse
          end

          def compare_against_single_value(del_val, compare_val)
            cval = compare_val.first
            to_del = []
            del_val.each_with_index do |val, i|
              to_del << i if val == cval
            end
            to_del.sort.reverse
          end

          def do_deletes(to_delete, vals)
            to_delete.each { |i| vals.delete_at(i) }
            return nil if vals.empty?

            vals.join(delim)
          end

          def grouped?
            !group.empty?
          end

          def validate_groups(groups, orig_del_val)
            orig_length = orig_del_val.length
            lengths = groups.map(&:length).uniq
            return :valid if lengths.length == 1 || orig_length == lengths.first
            return :ragged_group_length if lengths.length > 1

            :orig_vs_group_length_mismatch
          end

          def report_group_issue(validation, row)
            grpfields = group.join(", ")
            case validation
            when :ragged_group_length
              msg = "One or more grouped fields (#{grpfields}) has different "\
                "number of values than the others"
            when :orig_vs_group_length_mismatch
              msg = "Grouped fields (#{grpfields}) have different number of "\
                "values than #{delete} field"
            end
            puts %(#{Kiba::Extend.warning_label}: #{msg} in #{row})
          end
        end
      end
    end
  end
end
