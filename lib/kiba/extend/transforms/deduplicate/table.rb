# frozen_string_literal: true

module Kiba
  module Extend
    module Transforms
      module Deduplicate
        # Given a field on which to deduplicate, removes duplicate
        #   rows from table. The first row of each set of rows containing the
        #   same value in the given field. Various additional functionality
        #   is configurable via the arguments passed to the transform. See
        #   examples and {#initialize} for details.
        #
        # Tip: Use {CombineValues::FromFieldsWithDelimiter} or
        #   {CombineValues::FullRecord} to create a combined field on
        #   which to deduplicate
        #
        # @note This transform runs in memory, so for very large
        #   sources, it may take a long time or fail. In this case,
        #   use a combination of {Deduplicate::Flag} and
        #   {FilterRows::FieldEqualTo}
        #
        # @example With defaults
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table, field: :combine
        #   xform = Deduplicate::Table.new(field: :combine)
        #
        #   input = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #     {foo: "c", bar: "d", baz: "i", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "j", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "k", combine: "c d"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example When delete_field == true
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table,
        #   #   field: :combine,
        #   #   delete_field: true
        #   xform = Deduplicate::Table.new(field: :combine, delete_field: true)
        #
        #   input = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #     {foo: "c", bar: "d", baz: "i", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "j", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "k", combine: "c d"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", bar: "b", baz: "f"},
        #     {foo: "c", bar: "d", baz: "g"},
        #     {foo: "c", bar: "e", baz: "h"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Gathering examples
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table,
        #   #   field: :combine,
        #   #   delete_field: true,
        #   #   example_source_field: :baz,
        #   #   max_examples: 2,
        #   #   example_target_field: :ex,
        #   #   example_delim: " ; "
        #   xform = Deduplicate::Table.new(field: :combine, delete_field: true,
        #     example_source_field: :baz, max_examples: 2,
        #     example_target_field: :ex, example_delim: " ; ")
        #
        #   input = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #     {foo: "c", bar: "d", baz: "i", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "j", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "k", combine: "c d"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", bar: "b", baz: "f", ex: "f ; f"},
        #     {foo: "c", bar: "d", baz: "g", ex: "g ; i"},
        #     {foo: "c", bar: "e", baz: "h", ex: "h"},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Reporting occurrence count
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table,
        #   #   field: :combine,
        #   #   delete_field: true,
        #   #   example_source_field: :baz,
        #   #   max_examples: 2,
        #   #   include_occs: true
        #   xform = Deduplicate::Table.new(field: :combine, delete_field: true,
        #     example_source_field: :baz, max_examples: 2,
        #     include_occs: true
        #   )
        #   input = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #     {foo: "c", bar: "d", baz: "i", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "j", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "k", combine: "c d"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", bar: "b", baz: "f", examples: "f|f", occurrences: 2},
        #     {foo: "c", bar: "d", baz: "g", examples: "g|i", occurrences: 4},
        #     {foo: "c", bar: "e", baz: "h", examples: "h", occurrences: 1},
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Compiling unique field values into one field
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table,
        #   #   field: :combine,
        #   #   delete_field: true,
        #   #   compile_uniq_fieldvals: true,
        #   #   compile_delim: ", "
        #   xform = Deduplicate::Table.new(field: :combine, delete_field: true,
        #     compile_uniq_fieldvals: true, compile_delim: ", ")
        #   input = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #     {foo: "c", bar: "d", baz: "i", combine: "c d"},
        #     {foo: "c", bar: "d", baz: "j", combine: "c d"},
        #     {foo: "c", bar: "d", baz: nil, combine: "c d"},
        #     {foo: "c", bar: "d", baz: "k", combine: "c d"},
        #     {foo: "e", bar: "f", baz: nil, combine: "e f"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {foo: "a", bar: "b", baz: "f"},
        #     {foo: "c", bar: "d", baz: "g, i, j, k"},
        #     {foo: "c", bar: "e", baz: "h"},
        #     {foo: "e", bar: "f", baz: ""}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Combining examples, occs, and unique field value compile
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table,
        #   #   field: :combine,
        #   #   delete_field: true,
        #   #   example_source_field: :foo,
        #   #   example_target_field: :ex,
        #   #   max_examples: 4,
        #   #   include_occs: true,
        #   #   occs_target_field: :occs,
        #   #   compile_uniq_fieldvals: true,
        #   #   compile_delim: ", "
        #   xform = Deduplicate::Table.new(
        #     field: :combine,
        #     delete_field: true,
        #     example_source_field: :foo,
        #     example_target_field: :ex,
        #     max_examples: 4,
        #     include_occs: true,
        #     occs_target_field: :occs,
        #     compile_uniq_fieldvals: true,
        #     compile_delim: ", "
        #   )
        #   input = [
        #     {foo: "a", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "aa", bar: "b", baz: "f", combine: "a b"},
        #     {foo: "c", bar: "d", baz: "g", combine: "c d"},
        #     {foo: "cc", bar: "d", baz: "", combine: "c d"},
        #     {foo: "c", bar: "e", baz: "h", combine: "c e"},
        #     {foo: "ccc", bar: "d", baz: "i", combine: "c d"},
        #     {foo: "cc", bar: "d", baz: "j", combine: "c d"},
        #     {foo: "c", bar: "d", baz: nil, combine: "c d"},
        #     {foo: "c", bar: "d", baz: "k", combine: "c d"},
        #     {foo: "e", bar: "f", baz: nil, combine: "e f"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {occs: 2, ex: "a|aa", bar: "b", baz: "f"},
        #     {occs: 6, ex: "c|cc|ccc|cc", bar: "d", baz: "g, i, j, k"},
        #     {occs: 1, ex: "c", bar: "e", baz: "h"},
        #     {occs: 1, ex: "e", bar: "f", baz: ""}
        #   ]
        #   expect(result).to eq(expected)
        #
        # @example Compiling unique field values keeping dedupe field
        #   # Used in pipeline as:
        #   # transform Deduplicate::Table,
        #   #   field: :combine,
        #   #   delete_field: false,
        #   #   compile_uniq_fieldvals: true,
        #   #   compile_delim: ", "
        #   xform = Deduplicate::Table.new(field: :combine, delete_field: false,
        #     compile_uniq_fieldvals: true, compile_delim: ", ")
        #   input = [
        #     {baz: "f", combine: "a b"},
        #     {baz: "f", combine: "a b"},
        #     {baz: "g", combine: "c d"},
        #     {baz: "", combine: "c d"},
        #     {baz: "h", combine: "c e"},
        #     {baz: "i", combine: "c d"},
        #     {baz: "j", combine: "c d"},
        #     {baz: nil, combine: "c d"},
        #     {baz: "k", combine: "c d"},
        #     {baz: nil, combine: "e f"}
        #   ]
        #   result = Kiba::StreamingRunner.transform_stream(input, xform)
        #     .map{ |row| row }
        #   expected = [
        #     {baz: "f", combine: "a b"},
        #     {baz: "g, i, j, k", combine: "c d"},
        #     {baz: "h", combine: "c e"},
        #     {baz: "", combine: "e f"}
        #   ]
        #   expect(result).to eq(expected)
        # @since 2.2.0
        class Table
          # @param field [Symbol] name of field on which to deduplicate
          # @param delete_field [Boolean] whether to delete the deduplication
          #   field after doing deduplication
          # @param example_source_field [nil, Symbol] field containing values to
          #   be compiled as examples
          # @param max_examples [Integer] maximum number of example values to
          #   return
          # @param example_target_field [Symbol] name of field in which to
          #   report example values
          # @param example_delim [String] used to join multiple example values
          # @param include_occs [Boolean] whether to report number of
          #   occurrences of each field value being deduplicated on
          # @param occs_target_field [Symbol] name of field in which to report
          #   occurrences
          # @param compile_uniq_fieldvals [Boolean] whether to compile all
          #   unique values of each field across duplicate row set into the row
          #   that is kept. Values of each field are concatenated in order of
          #   row occurrence, then deduplicated
          # @param compile_delim [String] used to join compiled unique field
          #   values
          def initialize(field:, delete_field: false, example_source_field: nil,
            max_examples: 10, example_target_field: :examples,
            example_delim: Kiba::Extend.delim,
            include_occs: false, occs_target_field: :occurrences,
            compile_uniq_fieldvals: false, compile_delim: Kiba::Extend.delim)
            @field = field
            @deduper = {}
            @delete = delete_field
            @example = example_source_field
            @max_examples = max_examples
            @ex_target = example_target_field
            @delim = example_delim
            @occs = include_occs
            @occ_target = occs_target_field
            @compile_uniq_fieldvals = compile_uniq_fieldvals
            @compile_delim = compile_delim
          end

          # @param row [Hash{ Symbol => String, nil }]
          def process(row)
            field_val = row.fetch(field, nil)
            return if field_val.blank?

            get_row(field_val, row)
            get_occ(field_val, row) if occs
            get_example(field_val, row) if example
            compile_values(field_val, row) if compile_uniq_fieldvals
            nil
          end

          def close
            deduper.each do |_val, hash|
              row = hash[:row]
              add_example_field(row, hash) if example
              row[occ_target] = hash[:occs] if occs
              row = compiled_row(hash, row) if compile_uniq_fieldvals
              row.delete(field) if delete
              yield row
            end
          end

          def compiled_row(hash, row)
            row.map do |fld, val|
              if fld == example
                [fld, nil]
              elsif [field, ex_target, occ_target].include?(fld)
                [fld, val]
              else
                [fld, hash[:fieldvals][fld].join(compile_delim)]
              end
            end.compact.to_h.compact
          end

          private

          attr_reader :field, :deduper, :delete, :example, :max_examples,
            :ex_target, :delim, :occs, :occ_target, :compile_uniq_fieldvals,
            :compile_delim

          def get_row(field_val, row)
            return if deduper.key?(field_val)

            hash = {row: row}
            hash[:examples] = [] if example
            hash[:occs] = 0 if occs
            hash[:fieldvals] = set_up_fieldvals(row) if compile_uniq_fieldvals
            deduper[field_val] = hash
          end

          def set_up_fieldvals(row)
            thisrow = row.dup
            thisrow.delete(field)
            thisrow.map { |field, val| [field, Set[val]] }.to_h
          end

          def get_occ(field_val, row) = deduper[field_val][:occs] += 1

          def get_example(field_val, row)
            return if deduper[field_val][:examples].length == max_examples

            deduper[field_val][:examples] << row[example]
          end

          def compile_values(field_val, row)
            target = deduper[field_val][:fieldvals]
            row.each do |f, v|
              next if f == field || v.blank?

              target[f] << v
            end
          end

          def add_example_field(row, hash)
            row[ex_target] = hash[:examples].join(delim)
          end
        end
      end
    end
  end
end
