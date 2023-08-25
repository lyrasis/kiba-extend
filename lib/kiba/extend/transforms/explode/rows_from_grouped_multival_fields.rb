# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Explode
        # Creates a new row for each value position in a multivalued field
        #   group. For instance, if the values in "name" and "role" fields
        #   repeat together, this will create a row with the first values of
        #   "name" and "role", another row for the second values of "name"
        #   and "role", and so on.
        #
        # If the number of values in grouped multivalued fields is uneven
        #   (e.g. 3 names, but 2 roles), the missing values in the later
        #   rows will be `nil`, or the placeholder string value if given.
        #
        # Note that:
        #
        # - If the value of any grouped fields is `nil` or an empty string,
        #   that field, for the affected row, is treated like any other
        #   field in the row (i.e. not part of the group).
        # - Empty/missing values delimited as such in a multivalued grouped
        #   field get treated as empty string values.
        #
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Explode::RowsFromGroupedMultivalFields,
        #   #   fields: %i[name role]
        #   xform = Explode::RowsFromGroupedMultivalFields.new(
        #     fields: %i[name role]
        #   )
        #   input = [
        #     {id: "1", name: "Acme|Smith|Bond", role: "pub|pub|prt"},
        #     {id: "2", name: "Acme|Smith|Bond", role: "pub||prt"},
        #     {id: "3", name: "Acme|Smith|Bond", role: "pub|prt"},
        #     {id: "3.5", name: "Acme|Smith|Bond", role: "|pub|prt"},
        #     {id: "3.6", name: "Acme|Smith|Bond", role: "pub|prt|"},
        #     {id: "4", name: "Acme||Bond", role: "pub|pub|prt"},
        #     {id: "5", name: "Acme|Smith", role: "pub|pub|prt"},
        #     {id: "6", name: "Acme|Smith|Bond", role: ""},
        #     {id: "7", name: nil, role: "pub|pub|prt"},
        #     {id: "8", name: nil, role: nil},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "1", name: "Acme", role: "pub"},
        #     {id: "1", name: "Smith", role: "pub"},
        #     {id: "1", name: "Bond", role: "prt"},
        #     {id: "2", name: "Acme", role: "pub"},
        #     {id: "2", name: "Smith", role: ""},
        #     {id: "2", name: "Bond", role: "prt"},
        #     {id: "3", name: "Acme", role: "pub"},
        #     {id: "3", name: "Smith", role: "prt"},
        #     {id: "3", name: "Bond", role: nil},
        #     {id: "3.5", name: "Acme", role: ""},
        #     {id: "3.5", name: "Smith", role: "pub"},
        #     {id: "3.5", name: "Bond", role: "prt"},
        #     {id: "3.6", name: "Acme", role: "pub"},
        #     {id: "3.6", name: "Smith", role: "prt"},
        #     {id: "3.6", name: "Bond", role: ""},
        #     {id: "4", name: "Acme", role: "pub"},
        #     {id: "4", name: "", role: "pub"},
        #     {id: "4", name: "Bond", role: "prt"},
        #     {id: "5", name: "Acme", role: "pub"},
        #     {id: "5", name: "Smith", role: "pub"},
        #     {id: "5", name: nil, role: "prt"},
        #     {id: "6", name: "Acme", role: ""},
        #     {id: "6", name: "Smith", role: ""},
        #     {id: "6", name: "Bond", role: ""},
        #     {id: "7", name: nil, role: "pub"},
        #     {id: "7", name: nil, role: "pub"},
        #     {id: "7", name: nil, role: "prt"},
        #     {id: "8", name: nil, role: nil}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example With placeholder
        #   # Used in pipeline as:
        #   # transform Explode::RowsFromGroupedMultivalFields,
        #   #   fields: %i[name role],
        #   #   placeholder: "NULL"
        #   xform = Explode::RowsFromGroupedMultivalFields.new(
        #     fields: %i[name role], placeholder: "NULL"
        #   )
        #   input = [
        #     {id: "1", name: "Acme|Smith|Bond", role: "pub|pub|prt"},
        #     {id: "2", name: "Acme|Smith|Bond", role: "pub||prt"},
        #     {id: "3", name: "Acme|Smith|Bond", role: "pub|prt"},
        #     {id: "4", name: "Acme||Bond", role: "pub|pub|prt"},
        #     {id: "5", name: "Acme|Smith", role: "pub|pub|prt"},
        #     {id: "6", name: "Acme|Smith|Bond", role: ""},
        #     {id: "7", name: nil, role: "pub|pub|prt"},
        #     {id: "8", name: nil, role: nil},
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {id: "1", name: "Acme", role: "pub"},
        #     {id: "1", name: "Smith", role: "pub"},
        #     {id: "1", name: "Bond", role: "prt"},
        #     {id: "2", name: "Acme", role: "pub"},
        #     {id: "2", name: "Smith", role: ""},
        #     {id: "2", name: "Bond", role: "prt"},
        #     {id: "3", name: "Acme", role: "pub"},
        #     {id: "3", name: "Smith", role: "prt"},
        #     {id: "3", name: "Bond", role: "NULL"},
        #     {id: "4", name: "Acme", role: "pub"},
        #     {id: "4", name: "", role: "pub"},
        #     {id: "4", name: "Bond", role: "prt"},
        #     {id: "5", name: "Acme", role: "pub"},
        #     {id: "5", name: "Smith", role: "pub"},
        #     {id: "5", name: "NULL", role: "prt"},
        #     {id: "6", name: "Acme", role: ""},
        #     {id: "6", name: "Smith", role: ""},
        #     {id: "6", name: "Bond", role: ""},
        #     {id: "7", name: nil, role: "pub"},
        #     {id: "7", name: nil, role: "pub"},
        #     {id: "7", name: nil, role: "prt"},
        #     {id: "8", name: nil, role: nil}
        #   ]
        #   expect(result).to eq(expected)
        class RowsFromGroupedMultivalFields
          # @param fields [Symbol] the grouped fields from which rows will be
          #   created
          # @param delim [String] used to split `field` value.
          #   `Kiba::Extend.delim` used if value not given
          # @param placeholder [nil, String] used in empty field values when
          #   number of values in grouped fields are not equal
          def initialize(fields:, delim: nil, placeholder: nil)
            @fields = [fields].flatten
            @delim = delim || Kiba::Extend.delim
            @placeholder = placeholder
            @other_fields = nil
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            set_other_fields(row) unless other_fields
            other_field_vals = field_vals(row, other_fields)
            orig_vals = get_orig_vals(row)

            handle_unpopulated_vals(orig_vals[true], other_field_vals)
            split_vals = do_val_splits(orig_vals[false])

            if split_vals
              split_vals.each { |sval| yield other_field_vals.merge(sval) }
            else
              yield row
            end
            nil
          end

          private

          attr_reader :fields, :delim, :placeholder, :other_fields

          def set_other_fields(row)
            @other_fields = row.keys - fields
          end

          def field_vals(row, fields)
            fields.map { |field| [field, row[field]] }
              .to_h
          end

          def get_orig_vals(row)
            field_vals(row, fields)
              .group_by { |field, val| val.blank? }
              .transform_values { |vals| vals.to_h }
          end

          def handle_unpopulated_vals(vals, other_field_vals)
            return unless vals

            other_field_vals.merge!(vals)
          end

          def do_val_splits(vals)
            return unless vals

            svals = vals.transform_values { |val| val.split(delim, -1) }
            (vals.count == 1) ? single_val_split(svals) : multi_val_split(svals)
          end

          def single_val_split(vals)
            field = vals.keys.first
            vals[field].map { |val| {field => val} }
          end

          def multi_val_split(vals)
            by_ct = vals.group_by { |f, v| v.length }
              .transform_values! { |v| v.to_h }
            max = by_ct.keys.max
            basefield = by_ct[max].keys.first
            basevals = by_ct[max][basefield]
            vals.delete(basefield)

            basevals.map { |val| row_for_val(basefield, val, vals) }
          end

          def row_for_val(basefield, val, vals)
            {basefield => val}.merge(next_values(vals))
          end

          def next_values(vals)
            nextval = vals.map { |field, values| [field, values.shift] }
              .to_h
            return nextval unless placeholder

            nextval.transform_values { |val| val || placeholder }
          end
        end
      end
    end
  end
end
